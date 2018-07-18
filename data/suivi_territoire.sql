SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

CREATE SCHEMA pr_monitoring_flora_territory;

SET search_path = pr_monitoring_flora_territory, pg_catalog;

SET default_with_oids = false;

------------------------
--TABLES AND SEQUENCES--
------------------------

CREATE TABLE t_infos_site (
    id_infos_site serial NOT NULL,
    id_base_site integer NOT NULL,
    cd_nom integer NOT NULL  
);
COMMENT ON TABLE pr_monitoring_flora_territory.t_infos_site IS 'Extension de t_base_sites de gn_monitoring, permet d\avoir les infos complémentaires d\un site';


CREATE TABLE cor_visit_grid (
    id_area integer NOT NULL,
    id_base_visit integer NOT NULL,
    presence boolean NOT NULL     
);
COMMENT ON TABLE pr_monitoring_flora_territory.cor_visit_grid IS 'Enregistrer la présence/absence d\une espèce dans une maille définie lors d\une visite';


CREATE TABLE cor_visit_perturbation (
    id_base_visit integer NOT NULL,
    id_nomenclature_perturbation integer NOT NULL   
);
COMMENT ON TABLE pr_monitoring_flora_territory.cor_visit_perturbation IS 'Extension de t_base_visit de gn_monitoring, enregistrer les perturbations constatées lors d\une visite';


---------------
--PRIMARY KEY--
---------------

ALTER TABLE ONLY t_infos_site 
    ADD CONSTRAINT pk_id_t_infos_site PRIMARY KEY (id_infos_site);

ALTER TABLE ONLY cor_visit_grid
    ADD CONSTRAINT pk_cor_visit_grid PRIMARY KEY (id_area, id_base_visit);

ALTER TABLE ONLY cor_visit_perturbation 
    ADD CONSTRAINT pk_cor_visit_perturbation PRIMARY KEY (id_base_visit, id_nomenclature_perturbation);



---------------
--FOREIGN KEY--
---------------

ALTER TABLE ONLY t_infos_site 
    ADD CONSTRAINT fk_infos_site_id_base_site FOREIGN KEY (id_base_site) REFERENCES gn_monitoring.t_base_sites (id_base_site) ON UPDATE CASCADE ON DELETE CASCADE; 

ALTER TABLE ONLY t_infos_site
    ADD CONSTRAINT fk_infos_site_cd_nom FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref (cd_nom) ON UPDATE CASCADE;


ALTER TABLE ONLY cor_visit_grid
    ADD CONSTRAINT fk_cor_visit_grid_id_base_visit FOREIGN KEY (id_base_visit) REFERENCES gn_monitoring.t_base_visits (id_base_visit) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_visit_grid
    ADD CONSTRAINT fk_cor_visit_grid_id_area FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas (id_area);


ALTER TABLE ONLY cor_visit_perturbation 
    ADD CONSTRAINT fk_cor_visit_perturbation_id_base_visit FOREIGN KEY (id_base_visit) REFERENCES gn_monitoring.t_base_visits (id_base_visit) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_visit_perturbation 
    ADD CONSTRAINT fk_cor_visit_perturbation_id_nomenclature_perturbation FOREIGN KEY (id_nomenclature_perturbation) REFERENCES ref_nomenclatures.t_nomenclatures (id_nomenclature) ON UPDATE CASCADE;


------------
--TRIGGERS--
------------
-- Idée: 
-- + Un trigger pour vérifier si id_nomenclature_perturbation dans la table cor_visit_perturbation 
--   correspond bien à celui stocké dans t_nomenclatures. 

--------
--DATA--
--------

INSERT INTO ref_nomenclatures.t_nomenclatures (id_type, cd_nomenclature, mnemonique, label_default, label_fr, definition_fr )
VALUES (ref_nomenclatures.get_id_nomenclature_type('TYPE_SITE'), 'ZP', 'Zone de prospection', 'Zone de prospection - suivi flore territoire', 'Zone de prospection',  'Zone de prospection issu du module suivi flore territoire');

-- PROVISOIRE A ADAPTER GRACE AU SHAPEFILE DU CBNA
INSERT INTO gn_monitoring.t_base_sites
(id_inventor, id_digitiser, id_nomenclature_type_site, base_site_name, base_site_description, base_site_code, first_use_date, geom )
SELECT 1, 1, 475, 'zp', '', id, '01-01-2018', ST_TRANSFORM(ST_SetSRID(geom, 2154), 4326)
FROM pr_monitoring_flora_territory.zp_tmp;

INSERT INTO pr_monitoring_flora_territory.t_infos_site (id_base_site, cd_nom)
SELECT id_base_site, zp.cd_nom
FROM gn_monitoring.t_base_sites bs
JOIN pr_monitoring_flora_territory.zp_tmp zp ON zp.id::character varying = bs.base_site_code;


INSERT INTO ref_geo.bib_areas_types (id_type, type_name, type_desc)
VALUES (203, 'Mailles25*25', 'Maille INPN 50*50 redécoupé en 25m');

INSERT INTO ref_geo.l_areas (id_type, area_name, area_code, geom, centroid, source)
SELECT 203, id, id, geom, ST_CENTROID(geom), 'INPN'
FROM pr_monitoring_flora_territory.maille_tmp;

INSERT INTO ref_geo.li_grids
SELECT area_code, id_area, ST_XMin(ST_Extent(geom)), ST_XMax(ST_Extent(geom)), ST_YMin(ST_Extent(geom)),ST_YMax(ST_Extent(geom))
FROM ref_geo.l_areas
WHERE id_type=203
GROUP by area_code, id_area;


INSERT INTO gn_monitoring.cor_site_area (id_base_site, id_area)
SELECT bs.id_base_site, a.id_area 
FROM ref_geo.l_areas a
JOIN gn_monitoring.t_base_sites bs ON ST_Within(ST_TRANSFORM(a.geom, 4326), bs.geom)
WHERE id_type=203;

-- TODO Mettre en paramètre l'id du module
INSERT INTO gn_monitoring.cor_site_application
SELECT  bs.id_base_site, MY_ID_MODULE
FROM gn_monitoring.t_base_sites bs
JOIN pr_monitoring_flora_territory.zp_tmp zp ON bs.base_site_code  = zp.id::character varying;

DROP TABLE pr_monitoring_flora_territory.zp_tmp;
DROP TABLE pr_monitoring_flora_territory.maille_tmp;

-- Créer la nomenclature des perturbations
INSERT INTO ref_nomenclatures.bib_nomenclatures_types (mnemonique, label_default, definition_default, label_fr, definition_fr)
VALUES ('TYPE_PERTURBATION', 'Type de perturbations', 'Nomenclature des types de perturbations.', 'Type de perturbations', 'Nomenclatures des types de perturbations.');



INSERT INTO ref_nomenclatures.t_nomenclatures (id_type, cd_nomenclature, mnemonique, label_default, definition_default, label_fr, definition_fr, id_broader, hierarchy) VALUES 
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'GeF', 'Gestion par le feu', 'Gestion par le feu', 'Type de perturbation: Gestion par le feu', 'Gestion par le feu', 'Type de perturbation: Gestion par le feu', 0, '118.001'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Bru', 'Brûlage contrôlé', 'Brûlage contrôlé', 'Gestion par le feu: Brûlage contrôlé', 'Brûlage contrôlé', 'Gestion par le feu: Brûlage contrôlé', 503 , '118.503.001'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Inc', 'Incendie', 'Incendie (naturel ou incontrôlé)', 'Gestion par le feu: Incendie (naturel ou incontrôlé)', 'Incendie (naturel ou incontrôlé)', 'Gestion par le feu: Incendie (naturel ou incontrôlé)', 503, '118.503.002'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'AcL', 'Activité de loisirs', 'Activité de loisirs', 'Type de perturbation: Activité de loisirs', 'Activité de loisirs', 'Type de perturbation: Activité de loisirs', 0, '118.002'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Rec', 'Récolte des fleurs', 'Récolte des fleurs', 'Activité de loisirs: Récolte des fleurs', 'Récolte des fleurs', 'Activité de loisirs: Récolte des fleurs', 523  , '118.506.001'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Arr', 'Arrachage des pieds', 'Arrachage des pieds', 'Activité de loisirs: Arrachage des pieds', 'Arrachage des pieds', 'Activité de loisirs: Arrachage des pieds', 523, '118.506.002'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Pie', 'Piétinement pédestre', 'Piétinement pédestre', 'Activité de loisirs: Piétinement pédestre', 'Piétinement pédestre', 'Activité de loisirs: Piétinement pédestre', 523, '118.506.003'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Veh', 'Véhicules à moteur', 'Véhicules à moteur', 'Activité de loisirs: Véhicules à moteur', 'Véhicules à moteur', 'Activité de loisirs: Véhicules à moteur', 523, '118.506.004'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Plo', 'Plongée dans un lac', 'Plongée dans un lac', 'Activité de loisirs: Plongée dans un lac', 'Plongée dans un lac', 'Activité de loisirs: Plongée dans un lac', 523, '118.506.005'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'GeE', 'Gestion de l''eau', 'Gestion de l''eau', 'Type de perturbation: Gestion de l''eau', 'Gestion de l''eau', 'Type de perturbation: Gestion de l''eau', 0, '118.003'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Pom', 'Pompage', 'Pompage', 'Gestion de l''eau: Pompage', 'Pompage', 'Gestion de l''eau: Pompage', 529, '118.003'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Drn', 'Drainage', 'Drainage', 'Gestion de l''eau: Drainage', 'Drainage', 'Gestion de l''eau: Drainage', 529, '118.529.001'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Irg', 'Irrigation par gravité', 'Irrigation par gravité', 'Gestion de l''eau: Irrigation par gravité', 'Irrigation par gravité', 'Gestion de l''eau: Irrigation par gravité', 529, '118.529.002'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Ira', 'Irrigation par aspersion', 'Irrigation par aspersion', 'Gestion de l''eau: Irrigation par aspersion', 'Irrigation par aspersion', 'Gestion de l''eau: Irrigation par aspersion', 529, '118.529.003'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Cur', 'Curage', 'Curage', 'Gestion de l''eau: Curage (fossé, mare, serve)', 'Curage', 'Gestion de l''eau: Curage (fossé, mare, serve)', 529, '118.529.004'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Ext', 'Extraction de granulats', 'Extraction de granulats', 'Gestion de l''eau: Extraction de granulats', 'Extraction de granulats', 'Gestion de l''eau: Extraction de granulats', 529, '118.529.005'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'AcA', 'Activités agricoles', 'Activités agricoles', 'Type de perturbation: Activités agricoles', 'Activités agricoles', 'Type de perturbation: Activités agricoles', 0, '118.004'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Lab', 'Labour', 'Labour', 'Activités agricoles: Labour', 'Labour', 'Activités agricoles: Labour', 536, '118.536.001'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Fer', 'Fertilisation', 'Fertilisation', 'Activités agricoles: Fertilisation', 'Fertilisation', 'Activités agricoles: Fertilisation', 536, '118.536.002'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Prp', 'Produits phyosanitaires', 'Produits phyosanitaires', 'Activités agricoles: Produits phyosanitaires (épandage)', 'Produits phyosanitaires', 'Activités agricoles: Produits phyosanitaires (épandage)', 536, '118.536.003'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Fau', 'Fauchaison', 'Fauchaison', 'Activités agricoles: Fauchaison', 'Fauchaison', 'Activités agricoles: Fauchaison', 536, '118.536.004'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Apb', 'Apport de blocs', 'Apport de blocs', 'Activités agricoles: Apport de blocs (déterrés par le labour)', 'Apport de blocs', 'Activités agricoles: Apport de blocs (déterrés par le labour)', 536, '118.536.005'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Gyr', 'Gyrobroyage', 'Gyrobroyage', 'Activités agricoles: Gyrobroyage', 'Gyrobroyage', 'Activités agricoles: Gyrobroyage', 536, '118.536.006'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Reg', 'Revégétalisation', 'Revégétalisation', 'Activités agricoles: Revégétalisation (sur semis)', 'Revégétalisation', 'Activités agricoles: Revégétalisation (sur semis)', 536, '118.536.007'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'AcF', 'Activités forestières', 'Activités forestières', 'Type de perturbation: Activités forestières', 'Activités forestières', 'Type de perturbation: Activités forestières', 0, '118.005'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Jpf', 'Jeune plantation de feuillus', 'Jeune plantation de feuillus', 'Activités forestières: Jeune plantation de feuillus', 'Jeune plantation de feuillus', 'Activités forestières: Jeune plantation de feuillus', 544, '118.544.001'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Jpm', 'Jeune plantation mixte', 'Jeune plantation mixte', 'Activités forestières: Jeune plantation mixte', 'Jeune plantation mixte', 'Activités forestières: Jeune plantation mixte', 544, '118.544.002'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Jpr', 'Jeune plantation de résineux', 'Jeune plantation de résineux', 'Activités forestières: Jeune plantation de résineux', 'Jeune plantation de résineux', 'Activités forestières: Jeune plantation de résineux', 544, '118.544.003'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Ela', 'Elagage', 'Elagage', 'Activités forestières: Elagage (haie et bord de route)', 'Elagage', 'Activités forestières: Elagage (haie et bord de route)', 544, '118.544.004'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Cec', 'Coupe d''éclaircie', 'Coupe d''éclaircie', 'Activités forestières: Coupe d''éclaircie', 'Coupe d''éclaircie', 'Activités forestières: Coupe d''éclaircie', 544, '118.544.005'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Cbl', 'Coupe à blanc', 'Coupe à blanc', 'Activités forestières: Coupe à blanc', 'Coupe à blanc', 'Activités forestières: Coupe à blanc', 544, '118.544.006'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Bcl', 'Bois coupé et laissé', 'Bois coupé et laissé', 'Activités forestières: Bois coupé et laissé sur place', 'Bois coupé et laissé', 'Activités forestières: Bois coupé et laissé sur place', 544, '118.544.007'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Opf', 'Ouverture de piste forestière', 'Ouverture de piste forestière', 'Activités forestières: Ouverture de piste forestière', 'Ouverture de piste forestière', 'Activités forestières: Ouverture de piste forestière', 544, '118.544.008'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'CpA', 'Comportement des animaux', 'Comportement des animaux', 'Type de perturbation: Comportement des animaux', 'Comportement des animaux', 'Type de perturbation: Comportement des animaux', 0, '118.006'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Jas', 'Jas', 'Jas', 'Comportement des animaux: Jas (couchades nocturnes des animaux domestiques)', 'Jas', 'Comportement des animaux: Jas (couchades nocturnes des animaux domestiques)', 553, '118.553.001'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Cha', 'Chaume', 'Chaume', 'Comportement des animaux: Chaume (couchades aux heures chaudes des animaux domestiques)', 'Chaume', 'Comportement des animaux: Chaume (couchades aux heures chaudes des animaux domestiques)', 553, '118.553.002'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Fau', 'Faune sauvage', 'Faune sauvage', 'Comportement des animaux: Faune sauvage (reposoir)', 'Faune sauvage', 'Comportement des animaux: Faune sauvage (reposoir)', 553, '118.553.003'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Psa', 'Piétinement sans déjection', 'Piétinement sans déjection', 'Comportement des animaux: Piétinement, sans apports de déjection', 'Piétinement sans déjection', 'Comportement des animaux: Piétinement, sans apports de déjection', 553, '118.553.004'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Pat', 'Pâturage', 'Pâturage', 'Comportement des animaux: Pâturage (sur herbacées exclusivement)', 'Pâturage', 'Comportement des animaux: Pâturage (sur herbacées exclusivement)', 553, '118.553.005'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Acl', 'Abroutissement et écorçage ', 'Abroutissement et écorçage ', 'Comportement des animaux: Abroutissement et écorçage (sur ligneux)', 'Abroutissement et écorçage ', 'Comportement des animaux: Abroutissement et écorçage (sur ligneux)', 553, '118.553.006'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'San', 'Sangliers labours grattis', 'Sangliers labours grattis', 'Comportement des animaux: Sangliers-labours et grattis', 'Sangliers labours grattis', 'Comportement des animaux: Sangliers-labours et grattis', 553, '118.553.007'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Mar', 'Marmottes terriers', 'Marmottes terriers', 'Comportement des animaux: Marmottes-terriers', 'Marmottes terriers', 'Comportement des animaux: Marmottes-terriers', 553, '118.553.008'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Che', 'Chenilles défoliation', 'Chenilles défoliation', 'Comportement des animaux: Chenilles-défoliation', 'Chenilles défoliation', 'Comportement des animaux: Chenilles-défoliation', 553, '118.553.009'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'PnE', 'Processus naturels d''érosion', 'Processus naturels d''érosion', 'Type de perturbation: Processus naturels d''érosion', 'Processus naturels d''érosion', 'Type de perturbation: Processus naturels d''érosion', 0, '118.007'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Sub', 'Submersion temporaire', 'Submersion temporaire', 'Processus naturels d''érosion: Submersion temporaire', 'Submersion temporaire', 'Processus naturels d''érosion: Submersion temporaire', 563, '118.563.001'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Env', 'Envasement', 'Envasement', 'Processus naturels d''érosion: Envasement', 'Envasement', 'Processus naturels d''érosion: Envasement', 563, '118.563.002'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Eng', 'Engravement', 'Engravement', 'Processus naturels d''érosion: Engravement (laves torrentielles et divagation d''une rivière)', 'Engravement', 'Processus naturels d''érosion: Engravement (laves torrentielles et divagation d''une rivière)', 563, '118.563.003'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Aam', 'Avalanche apport matériaux', 'Avalanche apport matériaux', 'Processus naturels d''érosion: Avalanche (apport de matériaux non triés)', 'Avalanche', 'Processus naturels d''érosion: Avalanche (apport de matériaux non triés)', 563, '118.563.004'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Evs', 'Erosion vastes surfaces', 'Erosion vastes surfaces', 'Processus naturels d''érosion:Erosion s''exerçant sur de vastes surfaces', 'Erosion vastes surfaces', 'Processus naturels d''érosion:Erosion s''exerçant sur de vastes surfaces', 563, '118.563.005'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Sbe', 'Sapement berge', 'Sapement berge', 'Processus naturels d''érosion: Sapement de la berge d''un cours d''eau', 'Sapement berge', 'Processus naturels d''érosion: Sapement de la berge d''un cours d''eau', 563, '118.563.006'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Art', 'Avalanche ramonage terrain', 'Avalanche ramonage terrain', 'Processus naturels d''érosion: Avalanche-ramonage du terrain', 'Avalanche ramonage terrain', 'Processus naturels d''érosion: Avalanche-ramonage du terrain', 563, '118.563.007'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Ebr', 'Eboulement récent', 'Eboulement récent', 'Processus naturels d''érosion: Eboulement récent', 'Eboulement récent', 'Processus naturels d''érosion: Eboulement récent', 563, '118.563.008'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'AmL', 'Aménagements lourds', 'Aménagements lourds', 'Type de perturbation: Aménagements lourds', 'Aménagements lourds', 'Type de perturbation: Aménagements lourds', 0, '118.008'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Car', 'Carrière en roche dure', 'Carrière en roche dure', 'Aménagements lourds: Carrière en roche dure', 'Carrière en roche dure', 'Aménagements lourds: Carrière en roche dure', 572, '118.572.001'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Fos', 'Fossé pare-blocs', 'Fossé pare-blocs', 'Aménagements lourds: Fossé pare-blocs', 'Fossé pare-blocs', 'Aménagements lourds: Fossé pare-blocs', 572, '118.572.002'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'End', 'Endiguement', 'Endiguement', 'Aménagements lourds: Endiguement', 'Endiguement', 'Aménagements lourds: Endiguement', 572, '118.572.003'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Ter', 'Terrassement aménagements lourds', 'Terrassement aménagements lourds', 'Aménagements lourds: Terrassement pour aménagements lourds', 'Terrassement aménagements lourds', 'Aménagements lourds: Terrassement pour aménagements lourds', 572, '118.572.004'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Deb', 'Déboisement avec désouchage', 'Déboisement avec désouchage', 'Aménagements lourds: Déboisement avec désouchage', 'Déboisement avec désouchage', 'Aménagements lourds: Déboisement avec désouchage', 572, '118.572.005'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Beg', 'Béton-goudron:revêtement', 'Béton-goudron:revêtement', 'Aménagements lourds: Béton, goudron-revêtement abiotique', 'Béton-goudron:revêtement', 'Aménagements lourds: Béton, goudron-revêtement abiotique', 572, '118.572.006'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'GeI', 'Gestion des invasives', 'Gestion des invasives', 'Type de perturbation: Gestion des invasives', 'Gestion des invasives', 'Type de perturbation: Gestion des invasives', 0, '118.009'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Arg', 'Arrachage', 'Arrachage', 'Gestion des invasives: Arrachage', 'Arrachage', 'Gestion des invasives: Arrachage', 579, '118.879.001'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Fag', 'Fauchage', 'Fauchage', 'Gestion des invasives: Fauchage', 'Fauchage', 'Gestion des invasives: Fauchage', 579, '118.879.002'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Dbs', 'Débroussaillage', 'Débroussaillage', 'Gestion des invasives: Débroussaillage', 'Débroussaillage', 'Gestion des invasives: Débroussaillage', 579, '118.879.003'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Reb', 'Recouvrement avec bâches', 'Recouvrement avec bâches', 'Gestion des invasives: Recouvrement avec bâches', 'Recouvrement avec bâches', 'Gestion des invasives:Recouvrement avec bâches', 579, '118.879.004')








;