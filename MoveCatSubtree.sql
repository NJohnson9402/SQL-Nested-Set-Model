IF NOT EXISTS (SELECT * FROM sys.objects WHERE [type] = 'P' AND [object_id] = OBJECT_ID('nsm.[MoveCatSubtree]'))
	EXEC('CREATE PROCEDURE nsm.[MoveCatSubtree] AS BEGIN SET NOCOUNT ON; END')
GO
--=============================================
--Author: NJohnson9402, aka natethedba.wordpress.com
--Created: 20170104
--Description: move a "subtree" in the nsm.Cat table to a new Parent node,
--& maintain NSM (Nested Set Model) position values & Depth.
--=============================================
ALTER PROCEDURE nsm.[MoveCatSubtree]
	@CatID INT
	, @NewParentID INT
	, @Debug BIT = 0
AS
BEGIN
	SET NOCOUNT ON;

	--Disable triggers during operations
	ALTER TABLE nsm.Cat DISABLE TRIGGER trg_Cat_DEL;
	ALTER TABLE nsm.Cat DISABLE TRIGGER trg_Cat_INS;
	ALTER TABLE nsm.Cat DISABLE TRIGGER trg_Cat_UPD;

	--Treat 0/-1/NULL the same: means we want to make the top of this subtree a Root node
	IF (@NewParentID <= 0 OR @NewParentID IS NULL)
	BEGIN
		SET @NewParentID = -1;
	END

	--Cannot move a subtree under itself
	ELSE IF @NewParentID IN (
		SELECT SubCat.CatID
		FROM nsm.Cat Cat
		JOIN nsm.Cat SubCat
				ON SubCat.PLeft BETWEEN Cat.PLeft AND Cat.PRight
		WHERE Cat.CatID = @CatID)
	BEGIN
		RAISERROR (N'Cannot move subtree to a node within itself.', 18, 1);
		RETURN;
	END

	--Cannot move subtree to a node that doesnt exist
	ELSE IF NOT EXISTS (SELECT 1 FROM nsm.Cat WHERE CatID = @NewParentID)
	BEGIN
		RAISERROR (N'Cannot move subtree to a node that doesn''t exist.', 18, 1);
		RETURN;
	END

	--Cannot move subtree that doesnt exist
	ELSE IF NOT EXISTS (SELECT 1 FROM nsm.Cat WHERE CatID = @CatID)
	BEGIN
		RAISERROR (N'Cannot move subtree that doesn''t exist.', 18, 1);
		RETURN;
	END

	--Get old Parent & Subtree size
	DECLARE @OldParentID INT
		, @SubtreeSize INT
		, @SubtreeOldLeft INT
		, @SubtreeOldRight INT
		, @SubtreeOldDepth INT

	SELECT @OldParentID = ParentID,  @SubtreeSize = PRight - PLeft + 1
		, @SubtreeOldLeft = PLeft, @SubtreeOldRight = PRight, @SubtreeOldDepth = Depth
	FROM nsm.Cat
	WHERE CatID = @CatID

	--Cannot move subtree to its own Parent, i.e. there's nothing to do b/c new parent is same as old
	IF @OldParentID = @NewParentID
	BEGIN
		RAISERROR (N'Cannot move subtree to its own parent.', 18, 1);
		RETURN;
	END

	--Get new Parent position
	DECLARE @NewParentRight INT
		, @NewParentDepth INT;

	--If we're going Root, place it to the Right of existing Roots
	IF @NewParentID = -1
	BEGIN
		SELECT @NewParentRight = MAX(PRight) + 1, @NewParentDepth = -1
		FROM nsm.Cat
	END
	--Else, place it to the Right of its new siblings-to-be
	ELSE
	BEGIN
		SELECT @NewParentRight = PRight, @NewParentDepth = Depth
		FROM nsm.Cat 
		WHERE CatID = @NewParentID
	END

	--Get new positions for use
	SELECT CatID
		, PLeft + @NewParentRight - @SubtreeOldLeft AS PLeft
		, PRight + @NewParentRight - @SubtreeOldLeft AS PRight
		, Depth + (@NewParentDepth - @SubtreeOldDepth) + 1 AS Depth
	INTO #MoveNodes
	FROM nsm.Cat
	WHERE CatID IN (
		SELECT SubCat.CatID
		FROM nsm.Cat Cat
		JOIN nsm.Cat SubCat
				ON SubCat.PLeft BETWEEN Cat.PLeft AND Cat.PRight
		WHERE Cat.CatID = @CatID
	)

	IF (@Debug = 1)
		SELECT * FROM #MoveNodes
		ORDER BY PLeft

	--Make gap in tree (at destination branch) equal to the SubtreeSize
	UPDATE nsm.Cat
	SET PLeft = CASE WHEN PLeft > @NewParentRight THEN PLeft + @SubtreeSize ELSE PLeft END,
		PRight = CASE WHEN PRight >= @NewParentRight THEN PRight + @SubtreeSize ELSE PRight END
	WHERE PRight >= @NewParentRight

	--Update Subtree positions to new ones
	UPDATE nsm.Cat
	SET PLeft = #MoveNodes.PLeft, PRight = #MoveNodes.PRight, Depth = #MoveNodes.Depth
	FROM nsm.Cat
	JOIN #MoveNodes
			ON nsm.Cat.CatID = #MoveNodes.CatID

	--Maintain the Adjacency-List part (set ParentID)
	UPDATE nsm.Cat
	SET ParentID = (CASE WHEN @NewParentID = -1 THEN NULL ELSE @NewParentID END)
	WHERE CatID = @CatID

	--Close gaps, i.e. after the Subtree is gone from its old Parent, said old parent node has no children;
	--while nodes to the right & above now have inflated values, except where they include the newly moved subtree.
	UPDATE nsm.Cat
	SET PLeft = CASE WHEN PLeft > @SubtreeOldRight THEN PLeft - @SubtreeSize ELSE PLeft END,
		PRight = CASE WHEN PRight >= @SubtreeOldRight THEN PRight - @SubtreeSize ELSE PRight END
	WHERE PRight >= @SubtreeOldRight

	--Re-enable triggers when done
	ALTER TABLE nsm.Cat ENABLE TRIGGER trg_Cat_DEL;
	ALTER TABLE nsm.Cat ENABLE TRIGGER trg_Cat_INS;
	ALTER TABLE nsm.Cat ENABLE TRIGGER trg_Cat_UPD;
END
GO
