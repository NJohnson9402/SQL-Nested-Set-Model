ALTER TRIGGER nsm.trg_Cat_UPD
	ON nsm.Cat
	INSTEAD OF UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

	--Don't allow updates to structural fields (Position, Depth) nor parent; really, you can only update Name.
	IF (EXISTS (SELECT 1
		FROM Deleted
		JOIN Inserted
			ON Inserted.CatID = Deleted.CatID
		WHERE Deleted.ParentID <> Inserted.ParentID
			OR Deleted.PLeft <> Inserted.PLeft
			OR Deleted.PRight <> Inserted.PRight
			OR Deleted.Depth <> Inserted.Depth
		))
	BEGIN
		RAISERROR (N'Cannot update position/parent values inline; use the dedicated stored-procedure to move nodes.', 18, 1)
		RETURN
	END

	--Don't allow updates to NULL values
	IF (EXISTS (SELECT 1
		FROM Deleted
		JOIN Inserted
			ON Inserted.CatID = Deleted.CatID
		WHERE Inserted.ParentID IS NULL
			OR Inserted.PLeft IS NULL
			OR Inserted.PRight IS NULL
			OR Inserted.Depth IS NULL
		))
	BEGIN
		RAISERROR (N'Cannot update values to NULL; use the dedicated stored-procedure to set a node to "root" (NULL parent).', 18, 1)
		RETURN
	END

	--Else, proceed with update -- you can only update the Name!
	UPDATE Cat SET Cat.[Name] = Inserted.[Name]
	FROM nsm.Cat
	JOIN Inserted
		ON Inserted.CatID = Cat.CatID
END
GO
