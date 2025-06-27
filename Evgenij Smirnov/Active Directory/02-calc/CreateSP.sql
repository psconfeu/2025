SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- THIS IS A SUPER NAIVE APPROACH
-- I'M SURE IT COULD BE OPTIMISED EVEN WITHOUT RESORTING TO GRAPH DATABASES
-- BUT GRAPH IS DEFINITELY THE WAY TO GO HERE IF DEALING WITH TENS OF MILLIONS ATOMIC RELATIONSHIPS

CREATE PROCEDURE UpdateRelationships
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE 
			@cur CURSOR,
			@icu CURSOR,
			@parent VARCHAR(8000),
			@child VARCHAR(8000),
			@grandchild VARCHAR(8000),
			@depth int,
			@newdepth int,
			@numadd bigint,
			@start datetime,
			@executionTime int
			
	SET @start = getdate()
	
	SET @depth = 0
	SET @numadd = 1

	WHILE @numadd > 0
	BEGIN
		SET @numadd = 0
		SET @depth = @depth + 1
		SET @newdepth = @depth + 1
		--PRINT 'Depth: ' + CAST(@depth AS VARCHAR)
		RAISERROR('Depth: %u',10,1,@depth) WITH NOWAIT
		SET @cur = CURSOR FAST_FORWARD FOR
		SELECT Parent, Child FROM GroupMemberships WHERE Explicit=@depth;
	
		OPEN @cur
		
		FETCH NEXT FROM @cur INTO @parent, @child
	
		WHILE @@FETCH_STATUS = 0 
		BEGIN
			SET @icu = CURSOR FAST_FORWARD FOR
			SELECT Child FROM GroupMemberships WHERE Parent=@child
			OPEN @icu
			FETCH NEXT FROM @icu INTO @grandchild
			WHILE @@FETCH_STATUS = 0 
			BEGIN
				IF (@parent LIKE @grandchild)
					RAISERROR('%s',10,1,@parent) WITH NOWAIT
				ELSE
					INSERT INTO GroupMemberships (Parent,Child,Explicit) VALUES (@parent, @grandchild, @newdepth)
					SET @numadd = @numadd + 1
				FETCH NEXT FROM @icu INTO @grandchild	
			END
			CLOSE @icu
			DEALLOCATE @icu
			FETCH NEXT FROM @cur INTO @parent, @child
		END
		CLOSE @cur    
		DEALLOCATE @cur
		-- PRINT 'Added: ' + CAST(@numadd AS VARCHAR)
		RAISERROR('Added: %I64d',10,1,@numadd) WITH NOWAIT
		SET @executionTime = datediff(s, @start, getdate())
		RAISERROR('Elapsed: %u seconds',10,1,@executionTime) WITH NOWAIT
	END
END