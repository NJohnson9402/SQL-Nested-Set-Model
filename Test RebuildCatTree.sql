--preview
USE DataModels;
SELECT * FROM nsm.Cats ORDER BY PLeft

/*
--test 1: Smush/Smash/Smosh -> Smash/Smosh/Smush (alphabetical)
SET XACT_ABORT ON;
BEGIN TRAN test1;

ALTER TABLE nsm.Cat DISABLE TRIGGER trg_Cat_UPD;
UPDATE nsm.Cat SET PLeft = 1, PRight = NULL WHERE Name = 'Smash'
UPDATE nsm.Cat SET PLeft = 2, PRight = NULL WHERE Name = 'Smosh'
UPDATE nsm.Cat SET PLeft = 3, PRight = NULL WHERE Name = 'Smush'
ALTER TABLE nsm.Cat ENABLE TRIGGER trg_Cat_UPD;

EXEC nsm.RebuildCatTree @ParentID = 5, @Position = 10
SELECT * FROM nsm.Cats ORDER BY PLeft

ROLLBACK TRAN test1;
*/
/*
--test 2: entire tree, no change expected
SET XACT_ABORT ON;
BEGIN TRAN test2;

EXEC nsm.RebuildCatTree --@ParentID = NULL, @Position = 0 --DEFAULTS
SELECT * FROM nsm.Cats ORDER BY PLeft

ROLLBACK TRAN test2;
*/
/*
--test 3: re-arrange children of Fluffy
/*
 > Fluffy          | to -> |  > Fluffy
 >  > Mittens      | to -> |  >  > Gidget
 >  >  > Jack      | to -> |  >  >  > Widget
 >  >  >  > Smush  | to -> |  >  > Mittens
 >  >  >  > Smash  | to -> |  >  >  > Jack
 >  >  >  > Smosh  | to -> |  >  >  >  > Smush
 >  > Widget       | to -> |  >  >  >  > Smosh
 >  >  > Gidget    | to -> |  >  >  >  > Smash
*/
SET XACT_ABORT ON;
BEGIN TRAN test3;

ALTER TABLE nsm.Cat DISABLE TRIGGER trg_Cat_UPD;
UPDATE nsm.Cat SET PLeft = 1, ParentID = 3, PRight = NULL WHERE Name = 'Gidget'
UPDATE nsm.Cat SET PLeft = 2, ParentID = 11, PRight = NULL WHERE Name = 'Widget'
UPDATE nsm.Cat SET PLeft = 3, PRight = NULL WHERE Name = 'Mittens'
UPDATE nsm.Cat SET PLeft = 4, PRight = NULL WHERE Name = 'Jack'
UPDATE nsm.Cat SET PLeft = 5, PRight = NULL WHERE Name = 'Smush'
UPDATE nsm.Cat SET PLeft = 6, PRight = NULL WHERE Name = 'Smosh'
UPDATE nsm.Cat SET PLeft = 7, PRight = NULL WHERE Name = 'Smash'
ALTER TABLE nsm.Cat ENABLE TRIGGER trg_Cat_UPD;

DECLARE @ParentID INT, @Position INT, @Depth INT
SELECT @ParentID = CatID, @Position = PLeft, @Depth = Depth
	FROM nsm.Cat WHERE Name = 'Fluffy'

EXEC nsm.RebuildCatTree @ParentID = @ParentID, @Position = @Position, @Depth = @Depth

SELECT * FROM nsm.Cats ORDER BY PLeft
ROLLBACK TRAN test3;
*/
