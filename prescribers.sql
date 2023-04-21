
-- 1.  a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.

SELECT npi, SUM(total_claim_count)
FROM prescription
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1

-- 1881634483	99707 --

--     b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.

SELECT pr.npi,
	   nppes_provider_first_name AS first_name, 
       nppes_provider_last_org_name AS last_name,  
       specialty_description AS spec_des, 
       SUM(total_claim_count) AS sum_tot
FROM prescription as pr
LEFT JOIN prescriber as pre
ON pr.npi = pre.npi
GROUP BY 1,2,3,4
ORDER BY 5 DESC
LIMIT 1

-- 1881634483	"BRUCE"	"PENDLEY"	"Family Practice"	99707 --

-- 2.  a. Which specialty had the most total number of claims (totaled over all drugs)? 

SELECT specialty_description, SUM(total_claim_count)
FROM prescriber
JOIN prescription USING (npi)
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1

-- "Family Practice"	9752347 --

--     b. Which specialty had the most total number of claims for opioids?

SELECT specialty_description, SUM(total_claim_count)
FROM prescriber
JOIN prescription USING (npi)
JOIN drug USING (drug_name)
WHERE opioid_drug_flag = 'Y'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1

-- "Nurse Practitioner"	 900845 --

--     c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

--     d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

-- 3.  a. Which drug (generic_name) had the highest total drug cost?

SELECT generic_name, SUM(total_drug_cost)
FROM drug
JOIN prescription USING (drug_name)
GROUP BY 1
ORDER BY 2 DESC
LIMIT 3

-- "INSULIN GLARGINE,HUM.REC.ANLOG"	104264066.35 --

--     b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

SELECT generic_name,ROUND(sum(total_drug_cost)/sum(total_day_supply),2) as daily_cost
FROM prescription
JOIN drug USING (drug_name)
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5

SELECT drug.generic_name, ROUND((SUM(prescription.total_drug_cost)/SUM(prescription.total_day_supply)), 2) AS cost_per_day
FROM drug
JOIN prescription
ON prescription.drug_name = drug.drug_name
--WHERE prescription.total_drug_cost IS NOT NULL
GROUP BY 1
ORDER BY cost_per_day DESC;


-- "C1 ESTERASE INHIBITOR"	3495.22 --

-- 4.  a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.

SELECT drug_name,
       (CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
             WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
             ELSE 'neither' END) AS drug_type
FROM drug;

--     b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

SELECT SUM(total_drug_cost) AS money,
       (CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
             WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
             ELSE 'neither' END) AS type
FROM drug
JOIN prescription USING (drug_name)
GROUP BY 2
ORDER BY 1;

-- 105080626.37	"opioid"--

-- 5.  a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.

SELECT cbsa
FROM cbsa
WHERE cbsaname LIKE '%TN%'
GROUP BY 1
	

-- 10 --

--     b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

(SELECT c.cbsa, SUM(p.population)
FROM cbsa AS c
JOIN population AS p USING(fipscounty)
GROUP BY 1
ORDER BY 2 DESC
Limit 1)

UNION ALL

(SELECT c.cbsa, SUM(p.population)
FROM cbsa AS c
JOIN population AS p USING(fipscounty)
GROUP BY 1
ORDER BY 2 ASC
LIMIT 1)

-- "34980"	1830410 --
-- "34100"	116352 --

--     c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT p.fipscounty, p.population
FROM population AS p
LEFT JOIN cbsa AS c USING (fipscounty)
WHERE c.cbsa IS NULL
ORDER BY 2 DESC
LIMIT 1

-- "47155"	95523 --

-- 6.  a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT p.drug_name, total_claim_count
FROM prescription AS p
WHERE total_claim_count >= 3000

--     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT p.drug_name, total_claim_count, CASE WHEN opioid_drug_flag = 'Y' THEN 'Opioid' ELSE 'Other' END AS opiod
FROM prescription AS p
JOIN drug as d USING (drug_name)
WHERE total_claim_count >= 3000

--     c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT CONCAT(nppes_provider_first_name , ' ' , nppes_provider_last_org_name) AS name, 
	   drug_name, 
	   total_claim_count, 
	   CASE WHEN opioid_drug_flag = 'Y' THEN 'Opioid' ELSE 'Other' END AS opiod
FROM prescription AS p
JOIN drug as d USING (drug_name)
JOIN prescriber AS pr USING (npi)
WHERE total_claim_count >= 3000

-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--     a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Managment') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug           is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

SELECT npi, drug_name
FROM prescriber
CROSS JOIN drug 
WHERE nppes_provider_city = 'NASHVILLE' AND specialty_description = 'Pain Management' AND opioid_drug_flag='Y'
LIMIT 5

--     b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of               claims (total_claim_count).

SELECT p.npi, drug_name, total_claim_count
FROM prescriber AS p
CROSS JOIN drug
LEFT JOIN prescription AS pr
	USING(npi,drug_name)
WHERE nppes_provider_city = 'NASHVILLE' AND specialty_description = 'Pain Management' AND opioid_drug_flag='Y'
ORDER BY 2

--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

SELECT p.npi, drug_name, COALESCE(total_claim_count,0)
FROM prescriber AS p
CROSS JOIN drug
LEFT JOIN prescription AS pr
	USING(npi,drug_name)
WHERE nppes_provider_city = 'NASHVILLE' 
  AND specialty_description = 'Pain Management' 
  AND opioid_drug_flag='Y'
ORDER BY 2






