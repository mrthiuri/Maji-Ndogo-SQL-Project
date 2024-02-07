USE md_water_services;
SHOW Tables;
-- Understanding the data in our tables
-- 1. Location table
SELECT * FROM
md_water_services.location LIMIT 5;
-- 2.Visits table
SELECT * FROM 
visits LIMIT 5;
-- 3. Water source table
SELECT * FROM
water_source LIMIT 5;

-- Investigating the types of water sources in MajiNdogo
SELECT DISTINCT(type_of_water_source) AS water_types
FROM water_source;

-- Investigating the vists to water_sources
SELECT * FROM visits
WHERE time_in_queue > 500 
ORDER BY time_in_queue DESC;
-- The time is recorded in minutes in the database, we can standardise this measure by having a new column that records time in hours using a CTE rather than editing the entire table.

-- Investigating what type of water_sources have such long queue times
SELECT DISTINCT(type_of_water_source) FROM water_source
WHERE source_id IN ('AmRu14612224',
'HaRu19538224',
'AkRu05704224',
'HaRu20126224',
'SoRu35388224',
'KiZu31117224',
'KiRu29348224',
'SoRu37865224',
'SoRu38095224',
'HaRu17383224',
'AkLu02523224',
'KiRu30071224',
'KiRu29005224',
'SoRu38869224',
'SoRu36096224',
'SoRu36726224',
'AkRu08660224',
'KiRu30266224',
'SoRu38394224',
'HaRu17375224',
'AkRu03262224',
'KiRu30657224',
'AmRu13488224',
'KiRu30348224',
'KiRu26095224',
'KiRu25613224',
'KiRu25640224',
'SoRu37419224',
'HaRu19412224',
'KiRu27914224',
'SoRu36116224',
'KiRu26540224',
'AkRu05208224',
'AkRu03567224',
'HaRu20810224',
'KiRu28894224',
'AkRu08590224',
'KiRu25441224',
'AkRu04093224',
'AkRu06612224',
'SoRu35979224',
'AkRu07801224',
'AkRu06817224',
'AmBe11043224',
'AmAs10779224',
'AmAs10109224',
'SoRu35296224',
'AkKi01265224',
'AkRu05296224',
'SoRu34770224',
'KiRu26060224',
'AkRu03816224',
'SoRu36934224',
'AkRu05784224',
'KiZu31086224',
'AmAs10285224',
'AmPw12313224',
'AkRu08016224',
'KiRu25391224',
'SoRu35083224',
'SoRu37635224',
'AmDa12121224',
'SoRu39427224',
'KiZu31337224',
'HaRu19006224',
'HaRu18687224',
'KiZu31252224',
'KiRu25801224',
'SoRu36063224',
'KiZu31033224',
'SoKo33124224',
'KiRu25908224',
'SoRu37646224',
'KiRu28510224',
'AmRu15810224',
'KiZu31371224',
'KiRu27098224',
'AmBe11184224',
'SoRu38776224',
'AmRu14089224',
'KiRu25700224',
'KiRu27023224',
'AmAb09223224',
'AkRu08167224',
'AkRu05702224',
'AkRu04497224',
'KiZu31006224',
'KiRu30332224',
'HaRu17137224',
'HaRu20458224',
'HaRu20141224',
'AmBe11134224',
'KiIs24249224',
'HaRu19601224',
'SoRu35918224',
'SoRu37676224',
'AkRu04180224',
'AkRu02691224',
'AmAs10315224',
'KiRu29325224',
'AkKi00881224',
'AmRu14449224',
'KiRu25672224',
'AkRu04807224',
'AmBe11056224');
-- Shared taps seem to be havig the longer queue times

-- Assessing the quality of water_sources
SELECT * FROM water_quality;
-- The subjective quality score is the metric used to identify the water_source quality ranging from 1-10
/* Surveyors report states that where the quality_score was high no consequent visits were made, however, we'd love to verify this*/
SELECT COUNT(*) FROM water_quality 
WHERE subjective_quality_score = 10 -- home taps
AND visit_count=2;
/*There are 218 instances where more visits were made depsite high water quality rating.
This is indicative of some errors. An independt audit of the process would be appropriate */


-- Investigating pollution issues
SELECT * FROM well_pollution;
-- Categorising the pollutants
SELECT DISTINCT(results) FROM well_pollution
 AS pollutants;
 -- The pollutants are Contaminated: Biological, Contaminated: Chemical. Otherwise Clean
 -- Checking for data integrity

 -- a. Error detection
 SELECT * FROM
 well_pollution WHERE results = 'Clean' AND biological > 0.01;

 -- As per the scientists, any measure above 0.01 in the biological column should be marked contaminated. This would mean that our data is erroneous

 -- b. Error correction
 SELECT COUNT(*) FROM well_pollution
 WHERE description LIKE ('Clean %');
 
 /* TO correct this, we first create a copy of the table and effect the query
 and only after the query executes as intended then we can effect it on the original table*/

 DROP TABLE IF EXISTS md_water_services.well_pollution_copy;
 CREATE TABLE md_water_services.well_pollution_copy
 AS
	(SELECT * FROM well_pollution);
SELECT * FROM well_pollution_copy;

-- Segmenting our update into cases
	-- Case 1(Updating records containing 'Clean Bacteria E. coli' to 'Bacteria: E.coli'
		UPDATE well_pollution_copy 
        SET description = 'Bacteria: E. coli' WHERE description = 'Clean Bacteria: E. coli';
        
	-- Case 2(Updating records containing 'Clean Bacteria: Giardia Lamblia' to 'Bacteria: Giardia Lamblia'
		UPDATE well_pollution_copy
        SET description = 'Bacteria: Giardia Lamblia' WHERE description = 'Clean Bacteria: Giardia Lamblia';
	
    -- Disable safe_mode to effect the changes below
    SET SQL_SAFE_UPDATES = 0;
    
    -- Case 3(Updating result to 'Contaminated: Biological' where biological>0.01 and results='Clean'
		UPDATE well_pollution_copy
        SET results = 'Contaminated: Biological' WHERE 
        (results = 'Clean'AND biological > 0.01);

-- After confirming the above changes are in effect, we can then apply the changes to the orginal table
		UPDATE well_pollution
        SET description = 'Bacteria: E. coli' WHERE description = 'Clean Bacteria: E. coli';
        
        UPDATE well_pollution
        SET description = 'Bacteria: Giardia Lamblia' WHERE description = 'Clean Bacteria: Giardia Lamblia';
	
    	UPDATE well_pollution
        SET results = 'Contaminated: Biological' WHERE 
        (results = 'Clean'AND biological > 0.01);

DROP TABLE well_pollution_copy;
