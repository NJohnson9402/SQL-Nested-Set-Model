--Get the whole tree, in friendly view form
SELECT * FROM nsm.Cats
ORDER BY PLeft

--Get descendants of Stripes (not just children, but grandchildren etc.)
SELECT child.*
FROM nsm.Cat parent
JOIN nsm.Cats child
	ON child.PLeft > parent.PLeft
	AND child.PLeft < parent.PRight
WHERE parent.Name = 'Stripes'
ORDER BY child.PLeft

--Get ancestors of Smash
SELECT parent.*
FROM nsm.Cats parent
JOIN nsm.Cat child
	ON child.PLeft > parent.PLeft
	AND child.PLeft < parent.PRight
WHERE child.Name = 'Smash'
ORDER BY parent.PLeft

--Get Jack & siblings (Tigger, Simon; but not Mittens, Widget)
SELECT sib.*
FROM nsm.Cat me
JOIN nsm.Cats sib
	ON me.Depth = sib.Depth
	AND me.ParentID = sib.ParentID
WHERE me.Name = 'Jack'
ORDER BY sib.PLeft

--Get tree depth/width/count
SELECT TreeDepth = MAX(Depth), TreeWidth = MAX(PRight), NodeCount = COUNT(CatID)
FROM nsm.Cat
--> notice that width = count / 2
