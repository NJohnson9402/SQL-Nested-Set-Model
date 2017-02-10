USE DataModels;
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE [type] = 'P' AND [object_id] = OBJECT_ID('nsm.[RebuildCatTree]'))
	EXEC('CREATE PROCEDURE nsm.[RebuildCatTree] AS BEGIN SET NOCOUNT ON; END')
GO
-- =============================================
-- Author: NJohnson9402 aka natethedba.wordpress.com
-- Created: 20170209
-- Description: re-builds ("re-numbers") Cat tree
-- Warning: RECURSION ahead!
-- =============================================
ALTER PROCEDURE nsm.RebuildCatTree
	@ParentID INT = NULL
	, @Position INT = 0
	, @Depth INT = 0
AS
BEGIN
	SET NOCOUNT ON;
	
	--Starting depth; we will set this to the given Parent's Depth (or 0 if NULL)
	--DECLARE @Depth INT
	/*
	SELECT @Depth = (CASE WHEN @ParentID IS NULL THEN 0 ELSE Depth END)
		FROM nsm.Cat
		WHERE (@ParentID IS NULL AND ParentID IS NULL)
			OR ParentID = @ParentID
	*/

	--Cursor (loop) over child nodes of the given ParentID
	DECLARE @Curff CURSOR 
	SET @Curff = CURSOR READ_ONLY FAST_FORWARD FOR
		SELECT CatID
		FROM nsm.Cat
		WHERE (@ParentID IS NULL AND ParentID IS NULL)
			OR ParentID = @ParentID
		ORDER BY PLeft

	DECLARE @CatID INT
	OPEN @Curff
	FETCH NEXT FROM @Curff INTO @CatID

	WHILE @@FETCH_STATUS = 0
	BEGIN
		--Assumption: @Position starts at the CORRECT # from the given parent
		SET @Position = @Position + 1

		--@Depth gets incremented when you travel down from parent to child
		SET @Depth = @Depth + 1

		--Update this node's PLeft & Depth
		ALTER TABLE nsm.Cat DISABLE TRIGGER trg_Cat_UPD;

		UPDATE Cat SET PLeft = @Position, Depth = @Depth
		WHERE CatID = @CatID

		ALTER TABLE nsm.Cat ENABLE TRIGGER trg_Cat_UPD;

		--Recursively re-number this node's children
		RAISERROR ('Calling RebuildCatTree %d, %d --at Depth=%d', 0, 1, @CatID, @Position, @Depth) WITH NOWAIT
		
		EXEC @Position = nsm.RebuildCatTree @CatID, @Position, @Depth

		--It returns the last PRight set on the sub-tree, so add +1 to get this node's PRight
		SET @Position = @Position + 1

		--@Depth gets decremented when you travel up from child to parent
		SET @Depth = @Depth - 1

		--Update this node's PRight as mentioned above
		ALTER TABLE nsm.Cat DISABLE TRIGGER trg_Cat_UPD;

		UPDATE Cat SET PRight = @Position
		WHERE CatID = @CatID

		ALTER TABLE nsm.Cat ENABLE TRIGGER trg_Cat_UPD;

		--continue looping
		FETCH NEXT FROM @Curff INTO @CatID
	END
	CLOSE @Curff
	DEALLOCATE @Curff

	RAISERROR('RebuildCatTree for %d returning %d --at Depth=%d', 0, 1, @ParentID, @Position, @Depth) WITH NOWAIT

	--Return PRight as set on this node, so that caller knows what it's new PRight should be
	RETURN @Position
END
GO
