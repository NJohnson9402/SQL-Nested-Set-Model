--Schema [nsm] for "nested set model"
CREATE SCHEMA nsm AUTHORIZATION dbo;

--Base table. It may seem odd that PLeft/PRight/Depth are NULLable, but that's because
--we want to be able to INSERT just ParentID & Name, and let our triggers do the rest.
--Same reason that ParentID is NULLable & not a foreign-key; NULL means "root" node.
CREATE TABLE nsm.[Cat] (
	[CatID] [int] IDENTITY(1,1) NOT NULL,
	[ParentID] [int] NULL,
	[Name] [varchar](50) NOT NULL,
	[PLeft] [int] NULL,
	[PRight] [int] NULL,
	[Depth] [int] NULL,
	CONSTRAINT [PK_Cat] PRIMARY KEY CLUSTERED 
	(
		[CatID] ASC
	)
);

-- =============================================
-- Author: NJohnson9402, aka natethedba.wordpress.com
-- Created: 20170104
-- Description: a friendly view of the Cat tree using Depth to produce indented (with " > ") names.
-- =============================================
ALTER VIEW nsm.Cats
AS SELECT CatID, ParentID, DisplayName = REPLICATE(' > ', Depth) + Name
	, PLeft, PRight, Depth
FROM Cat;
