-- Script to insert references


-- -----------------------------------------------------------------------------
-- TAXONOMY

-- Create monitored taxons list by SFT protocol
INSERT INTO taxonomie.bib_listes (id_liste, nom_liste, desc_liste, regne, group2_inpn, code_liste)
SELECT
    (SELECT MAX(id_liste) + 1 FROM taxonomie.bib_listes),
    :'taxonListName',
    'Taxons suivis dans le protocole Suivi Flore Territoire',
    'Plantae',
    'Angiospermes',
    (SELECT MAX(id_liste) + 1 FROM taxonomie.bib_listes)
;


-- -----------------------------------------------------------------------------
-- COMMONS

-- Update SFT module
UPDATE gn_commons.t_modules
SET
    module_label = 'Suivi Flore Territoire',
    module_picto = 'fa-leaf',
    module_desc = 'Module de Suivi de la Flore d''un Territoire'
WHERE module_code ILIKE :'SFT'


