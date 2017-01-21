USE DataModels;
GO
ALTER TRIGGER nsm.trg_Cat_DEL
	ON nsm.Cat
	INSTEAD OF DELETE
AS 
BEGIN
	SET NOCOUNT ON;

	--Cannot function on more than 1 deleted record at a time
	IF (SELECT COUNT(1) FROM Deleted) > 1
	BEGIN
		RAISERROR (N'This table does not support multiple inserts in one SQL statement', 18, 1)
		RETURN
	END

	--Get properties of deleting node
	DECLARE @DelID INT, @DelParentID INT
		, @DelLeft INT, @DelRight INT
		, @DelDepth INT

	SELECT @DelID = CatID, @DelParentID = ParentID
		, @DelLeft = PLeft, @DelRight = PRight
		, @DelDepth = Depth
	FROM Deleted

	--Ready to delete the node
	DELETE FROM nsm.Cat
	WHERE CatID = @DelID

	--If furthest right root node, no need to move any others
	IF (@DelRight = (SELECT MAX(PRight) FROM nsm.Cat))
		RETURN;

	--Else, we have to shift nodes left & promote children
	ELSE
	BEGIN
		--shift everything left 2
		UPDATE nsm.Cat
		SET PLeft = (CASE WHEN PLeft > @DelRight THEN PLeft - 2 ELSE PLeft END)
		  , PRight = (CASE WHEN PRight >= @DelRight THEN PRight - 2 ELSE PRight END)
		WHERE PRight >= @DelRight

		--If leaf node, no need to move children.
		--Else, shift nodes back (left) by 2, if they are "above / right" of the deleted node;
		--then we need to "promote" children to next level up (or they'll be orphans!)
		--Children will be placed in deleted node's "space", i.e. squeezed between its old neighbors.
		IF (EXISTS (SELECT 1
					FROM nsm.Cat child
					WHERE child.ParentID = @DelID))
		BEGIN
			--set childrens' ParentID to old Parent, up Depth by 1, & subtract 1 from Positions
			UPDATE nsm.Cat
			SET ParentID = @DelParentID, Depth = @DelDepth
				, PLeft = PLeft - 1, PRight = PRight - 1
			WHERE ParentID = @DelID
		END
	END
END
GO
