CREATE TRIGGER nsm.trg_Cat_INS
	ON nsm.Cat
	AFTER INSERT
AS 
BEGIN
	SET NOCOUNT ON;

	--Cannot function on more than 1 inserted record at a time
	IF (SELECT COUNT(1) FROM Inserted) > 1
	BEGIN
		RAISERROR (N'This table does not support multiple inserts in one SQL statement', 18, 1)

		DELETE FROM nsm.Cat
		WHERE CatID IN (SELECT CatID FROM Inserted)

		RETURN
	END

	--If Root node, simply place at the end (right) of all other Roots (i.e. max-right)
	IF ((SELECT ParentID FROM Inserted) IS NULL
		OR (SELECT ParentID FROM Inserted) = -1) -- root node
	BEGIN
		DECLARE @Left INT	

		SELECT @Left = COALESCE(MAX(PRight), 0) + 1
		FROM Cat
		
		UPDATE Cat
		SET PLeft = @Left, PRight = @Left + 1, Depth = 0
		WHERE CatID = (SELECT CatID FROM Inserted)
	END
	--Else, shift ALL sub-trees over (right) by 2
	--& place the newly Inserted at the tail-end (right) of its siblings
	ELSE
	BEGIN
		DECLARE @ParentRight INT, @Depth INT

		SELECT @ParentRight = PRight, @Depth = Depth + 1
		FROM Cat
		WHERE CatID = (SELECT ParentID FROM Inserted)

		--SHIFT EVERYTHING ELSE OVER (right) 2
		UPDATE Cat
		SET PLeft = CASE WHEN PLeft > @ParentRight THEN PLeft + 2 ELSE PLeft END
		  , PRight = CASE WHEN PRight >= @ParentRight THEN PRight + 2 ELSE PRight END
		WHERE PRight >= @ParentRight

		--new record goes "below" (to the right of) its right-most sibling
		UPDATE Cat
		SET PLeft = @ParentRight, PRight = @ParentRight + 1
		  , Depth = @Depth
		WHERE CatID = (SELECT CatID FROM Inserted)
	END
END
GO
