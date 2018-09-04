SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

CREATE SCHEMA pr_monitoring_flora_territory;

SET search_path = pr_monitoring_flora_territory, pg_catalog, public;

SET default_with_oids = false;

------------------------
--TABLES AND SEQUENCES--
------------------------

CREATE TABLE t_infos_site (
    id_infos_site serial NOT NULL,
    id_base_site integer NOT NULL,
    cd_nom integer NOT NULL
    -- rajouter colonne nom de commune --
);
COMMENT ON TABLE pr_monitoring_flora_territory.t_infos_site IS 'Extension de t_base_sites de gn_monitoring, permet d\avoir les infos complémentaires d\un site';


CREATE TABLE cor_visit_grid (
    id_area integer NOT NULL,
    id_base_visit integer NOT NULL,
    presence boolean NOT NULL,
    uuid_base_visit UUID DEFAULT public.uuid_generate_v4() 
    -- rajouter uuid (id unique) pour chaque visite de la table cor_visit_grid --     
);
COMMENT ON TABLE pr_monitoring_flora_territory.cor_visit_grid IS 'Enregistrer la présence/absence d\une espèce dans une maille définie lors d\une visite';


CREATE TABLE cor_visit_perturbation (
    id_base_visit integer NOT NULL,
    id_nomenclature_perturbation integer NOT NULL   
);
COMMENT ON TABLE pr_monitoring_flora_territory.cor_visit_perturbation IS 'Extension de t_base_visit de gn_monitoring, enregistrer les perturbations constatées lors d\une visite';


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
    ADD CONSTRAINT fk_t_infos_site_id_base_site FOREIGN KEY (id_base_site) REFERENCES gn_monitoring.t_base_sites (id_base_site) ON UPDATE CASCADE ON DELETE CASCADE; 

ALTER TABLE ONLY t_infos_site
    ADD CONSTRAINT fk_t_infos_site_cd_nom FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref (cd_nom) ON UPDATE CASCADE;


ALTER TABLE ONLY cor_visit_grid
    ADD CONSTRAINT fk_cor_visit_grid_id_base_visit FOREIGN KEY (id_base_visit) REFERENCES gn_monitoring.t_base_visits (id_base_visit) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_visit_grid
    ADD CONSTRAINT fk_cor_visit_grid_id_area FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas (id_area);


ALTER TABLE ONLY cor_visit_perturbation 
    ADD CONSTRAINT fk_cor_visit_perturbation_id_base_visit FOREIGN KEY (id_base_visit) REFERENCES gn_monitoring.t_base_visits (id_base_visit) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_visit_perturbation 
    ADD CONSTRAINT fk_cor_visit_perturbation_id_nomenclature_perturbation FOREIGN KEY (id_nomenclature_perturbation) REFERENCES ref_nomenclatures.t_nomenclatures (id_nomenclature) ON UPDATE CASCADE;


--Créer la vue pour exporter les visites

    CREATE OR REPLACE VIEW pr_monitoring_flora_territory.export_visits AS 
WITH
    observers AS(
SELECT 
    v.id_base_visit,
    string_agg(roles.nom_role::text || ' ' ||  roles.prenom_role::text, ',') AS observateurs,
    roles.organisme AS organisme
FROM gn_monitoring.t_base_visits v
JOIN gn_monitoring.cor_visit_observer observer ON observer.id_base_visit = v.id_base_visit
JOIN utilisateurs.t_roles roles ON roles.id_role = observer.id_role
GROUP BY v.id_base_visit, roles.organisme
),
perturbations AS(
SELECT 
    v.id_base_visit,
    string_agg(n.label_default, ',') AS label_perturbation
FROM gn_monitoring.t_base_visits v
JOIN pr_monitoring_flora_territory.cor_visit_perturbation p ON v.id_base_visit = p.id_base_visit
JOIN ref_nomenclatures.t_nomenclatures n ON p.id_nomenclature_perturbation = n.id_nomenclature
GROUP BY v.id_base_visit
)
-- toutes les mailles d'un site et leur visites
SELECT sites.id_base_site, cor.id_area, visits.id_base_visit, grid.presence, visits.id_digitiser, visits.visit_date, visits.comments, visits.uuid_base_visit, ar.geom,
    per.label_perturbation,
    obs.observateurs,
    obs.organisme,
    sites.base_site_name,
    taxon.nom_valide,
    taxon.cd_nom
    
FROM gn_monitoring.t_base_sites sites
JOIN gn_monitoring.cor_site_area cor ON cor.id_base_site = sites.id_base_site
JOIN gn_monitoring.t_base_visits visits ON sites.id_base_site = visits.id_base_site
LEFT JOIN pr_monitoring_flora_territory.cor_visit_grid grid ON grid.id_area = cor.id_area AND grid.id_base_visit = visits.id_base_visit
JOIN observers obs ON obs.id_base_visit = visits.id_base_visit
JOIN perturbations per ON per.id_base_visit = visits.id_base_visit
JOIN pr_monitoring_flora_territory.t_infos_site info ON info.id_base_site = sites.id_base_site
JOIN taxonomie.taxref taxon ON taxon.cd_nom = info.cd_nom
JOIN ref_geo.l_areas ar ON ar.id_area = cor.id_area
ORDER BY visits.id_base_visit;

------------
--TRIGGERS--
------------
-- Idée: 
-- + Un trigger pour vérifier si id_nomenclature_perturbation dans la table cor_visit_perturbation 
--   correspond bien à celui stocké dans t_nomenclatures. 


--------------
-- DATA -----
--------------

-- créer nomenclature des perturbations-- 
INSERT INTO ref_nomenclatures.bib_nomenclatures_types (mnemonique, label_default, definition_default, label_fr, definition_fr)
    VALUES ('TYPE_PERTURBATION', 'Type de perturbations', 'Nomenclature des types de perturbations.', 'Type de perturbations', 'Nomenclatures des types de perturbations.');



-- insérer les types de perturbations --
-- problème id_broader ??
INSERT INTO ref_nomenclatures.t_nomenclatures (id_type, cd_nomenclature, mnemonique, label_default, definition_default, label_fr, definition_fr, id_broader, hierarchy) VALUES 
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'GeF', 'Gestion par le feu', 'Gestion par le feu', 'Type de perturbation: Gestion par le feu', 'Gestion par le feu', 'Type de perturbation: Gestion par le feu', 0, '118.001'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Bru', 'Brûlage contrôlé', 'Brûlage contrôlé', 'Gestion par le feu: Brûlage contrôlé', 'Brûlage contrôlé', 'Gestion par le feu: Brûlage contrôlé', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Bru') , '118.503.001'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Inc', 'Incendie', 'Incendie (naturel ou incontrôlé)', 'Gestion par le feu: Incendie (naturel ou incontrôlé)', 'Incendie (naturel ou incontrôlé)', 'Gestion par le feu: Incendie (naturel ou incontrôlé)', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Inc'), '118.503.002'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'AcL', 'Activité de loisirs', 'Activité de loisirs', 'Type de perturbation: Activité de loisirs', 'Activité de loisirs', 'Type de perturbation: Activité de loisirs', 0, '118.002'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Rec', 'Récolte des fleurs', 'Récolte des fleurs', 'Activité de loisirs: Récolte des fleurs', 'Récolte des fleurs', 'Activité de loisirs: Récolte des fleurs', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Rec') , '118.506.001'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Arr', 'Arrachage des pieds', 'Arrachage des pieds', 'Activité de loisirs: Arrachage des pieds', 'Arrachage des pieds', 'Activité de loisirs: Arrachage des pieds', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Arr'), '118.506.002'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Pie', 'Piétinement pédestre', 'Piétinement pédestre', 'Activité de loisirs: Piétinement pédestre', 'Piétinement pédestre', 'Activité de loisirs: Piétinement pédestre', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Pie'), '118.506.003'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Veh', 'Véhicules à moteur', 'Véhicules à moteur', 'Activité de loisirs: Véhicules à moteur', 'Véhicules à moteur', 'Activité de loisirs: Véhicules à moteur', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Veh'), '118.506.004'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Plo', 'Plongée dans un lac', 'Plongée dans un lac', 'Activité de loisirs: Plongée dans un lac', 'Plongée dans un lac', 'Activité de loisirs: Plongée dans un lac', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Plo'), '118.506.005'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'GeE', 'Gestion de l''eau', 'Gestion de l''eau', 'Type de perturbation: Gestion de l''eau', 'Gestion de l''eau', 'Type de perturbation: Gestion de l''eau', 0, '118.003'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Pom', 'Pompage', 'Pompage', 'Gestion de l''eau: Pompage', 'Pompage', 'Gestion de l''eau: Pompage', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Pom'), '118.003'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Drn', 'Drainage', 'Drainage', 'Gestion de l''eau: Drainage', 'Drainage', 'Gestion de l''eau: Drainage', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Drn'), '118.529.001'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Irg', 'Irrigation par gravité', 'Irrigation par gravité', 'Gestion de l''eau: Irrigation par gravité', 'Irrigation par gravité', 'Gestion de l''eau: Irrigation par gravité', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Irg'), '118.529.002'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Ira', 'Irrigation par aspersion', 'Irrigation par aspersion', 'Gestion de l''eau: Irrigation par aspersion', 'Irrigation par aspersion', 'Gestion de l''eau: Irrigation par aspersion', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Ira'), '118.529.003'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Cur', 'Curage', 'Curage', 'Gestion de l''eau: Curage (fossé, mare, serve)', 'Curage', 'Gestion de l''eau: Curage (fossé, mare, serve)', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Cur'), '118.529.004'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Ext', 'Extraction de granulats', 'Extraction de granulats', 'Gestion de l''eau: Extraction de granulats', 'Extraction de granulats', 'Gestion de l''eau: Extraction de granulats', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Ext'), '118.529.005'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'AcA', 'Activités agricoles', 'Activités agricoles', 'Type de perturbation: Activités agricoles', 'Activités agricoles', 'Type de perturbation: Activités agricoles', 0, '118.004'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Lab', 'Labour', 'Labour', 'Activités agricoles: Labour', 'Labour', 'Activités agricoles: Labour', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Lab'), '118.536.001'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Fer', 'Fertilisation', 'Fertilisation', 'Activités agricoles: Fertilisation', 'Fertilisation', 'Activités agricoles: Fertilisation', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Fer'), '118.536.002'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Prp', 'Produits phyosanitaires', 'Produits phyosanitaires', 'Activités agricoles: Produits phyosanitaires (épandage)', 'Produits phyosanitaires', 'Activités agricoles: Produits phyosanitaires (épandage)', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Prp'), '118.536.003'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Fauc', 'Fauchaison', 'Fauchaison', 'Activités agricoles: Fauchaison', 'Fauchaison', 'Activités agricoles: Fauchaison', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Fauc'), '118.536.004'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Apb', 'Apport de blocs', 'Apport de blocs', 'Activités agricoles: Apport de blocs (déterrés par le labour)', 'Apport de blocs', 'Activités agricoles: Apport de blocs (déterrés par le labour)', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Apb'), '118.536.005'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Gyr', 'Gyrobroyage', 'Gyrobroyage', 'Activités agricoles: Gyrobroyage', 'Gyrobroyage', 'Activités agricoles: Gyrobroyage', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Gyr'), '118.536.006'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Reg', 'Revégétalisation', 'Revégétalisation', 'Activités agricoles: Revégétalisation (sur semis)', 'Revégétalisation', 'Activités agricoles: Revégétalisation (sur semis)', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Reg'), '118.536.007'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'AcF', 'Activités forestières', 'Activités forestières', 'Type de perturbation: Activités forestières', 'Activités forestières', 'Type de perturbation: Activités forestières', 0, '118.005'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Jpf', 'Jeune plantation de feuillus', 'Jeune plantation de feuillus', 'Activités forestières: Jeune plantation de feuillus', 'Jeune plantation de feuillus', 'Activités forestières: Jeune plantation de feuillus', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Jpf'), '118.544.001'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Jpm', 'Jeune plantation mixte', 'Jeune plantation mixte', 'Activités forestières: Jeune plantation mixte', 'Jeune plantation mixte', 'Activités forestières: Jeune plantation mixte', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Jpm'), '118.544.002'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Jpr', 'Jeune plantation de résineux', 'Jeune plantation de résineux', 'Activités forestières: Jeune plantation de résineux', 'Jeune plantation de résineux', 'Activités forestières: Jeune plantation de résineux', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Jpr'), '118.544.003'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Ela', 'Elagage', 'Elagage', 'Activités forestières: Elagage (haie et bord de route)', 'Elagage', 'Activités forestières: Elagage (haie et bord de route)', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Ela'), '118.544.004'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Cec', 'Coupe d''éclaircie', 'Coupe d''éclaircie', 'Activités forestières: Coupe d''éclaircie', 'Coupe d''éclaircie', 'Activités forestières: Coupe d''éclaircie', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Cec'), '118.544.005'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Cbl', 'Coupe à blanc', 'Coupe à blanc', 'Activités forestières: Coupe à blanc', 'Coupe à blanc', 'Activités forestières: Coupe à blanc', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Cbl'), '118.544.006'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Bcl', 'Bois coupé et laissé', 'Bois coupé et laissé', 'Activités forestières: Bois coupé et laissé sur place', 'Bois coupé et laissé', 'Activités forestières: Bois coupé et laissé sur place', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Bcl'), '118.544.007'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Opf', 'Ouverture de piste forestière', 'Ouverture de piste forestière', 'Activités forestières: Ouverture de piste forestière', 'Ouverture de piste forestière', 'Activités forestières: Ouverture de piste forestière', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Opf'), '118.544.008'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'CpA', 'Comportement des animaux', 'Comportement des animaux', 'Type de perturbation: Comportement des animaux', 'Comportement des animaux', 'Type de perturbation: Comportement des animaux', 0, '118.006'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Jas', 'Jas', 'Jas', 'Comportement des animaux: Jas (couchades nocturnes des animaux domestiques)', 'Jas', 'Comportement des animaux: Jas (couchades nocturnes des animaux domestiques)', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Jas'), '118.553.001'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Cha', 'Chaume', 'Chaume', 'Comportement des animaux: Chaume (couchades aux heures chaudes des animaux domestiques)', 'Chaume', 'Comportement des animaux: Chaume (couchades aux heures chaudes des animaux domestiques)', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Cha'), '118.553.002'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Faus', 'Faune sauvage', 'Faune sauvage', 'Comportement des animaux: Faune sauvage (reposoir)', 'Faune sauvage', 'Comportement des animaux: Faune sauvage (reposoir)', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Faus'), '118.553.003'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Psa', 'Piétinement sans déjection', 'Piétinement sans déjection', 'Comportement des animaux: Piétinement, sans apports de déjection', 'Piétinement sans déjection', 'Comportement des animaux: Piétinement, sans apports de déjection', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Psa'), '118.553.004'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Pat', 'Pâturage', 'Pâturage', 'Comportement des animaux: Pâturage (sur herbacées exclusivement)', 'Pâturage', 'Comportement des animaux: Pâturage (sur herbacées exclusivement)', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Pat'), '118.553.005'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Acl', 'Abroutissement et écorçage ', 'Abroutissement et écorçage ', 'Comportement des animaux: Abroutissement et écorçage (sur ligneux)', 'Abroutissement et écorçage ', 'Comportement des animaux: Abroutissement et écorçage (sur ligneux)', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Acl'), '118.553.006'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'San', 'Sangliers labours grattis', 'Sangliers labours grattis', 'Comportement des animaux: Sangliers-labours et grattis', 'Sangliers labours grattis', 'Comportement des animaux: Sangliers-labours et grattis', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'San'), '118.553.007'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Mar', 'Marmottes terriers', 'Marmottes terriers', 'Comportement des animaux: Marmottes-terriers', 'Marmottes terriers', 'Comportement des animaux: Marmottes-terriers', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Mar'), '118.553.008'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Che', 'Chenilles défoliation', 'Chenilles défoliation', 'Comportement des animaux: Chenilles-défoliation', 'Chenilles défoliation', 'Comportement des animaux: Chenilles-défoliation', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Che'), '118.553.009'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'PnE', 'Processus naturels d''érosion', 'Processus naturels d''érosion', 'Type de perturbation: Processus naturels d''érosion', 'Processus naturels d''érosion', 'Type de perturbation: Processus naturels d''érosion', 0, '118.007'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Sub', 'Submersion temporaire', 'Submersion temporaire', 'Processus naturels d''érosion: Submersion temporaire', 'Submersion temporaire', 'Processus naturels d''érosion: Submersion temporaire', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Sub'), '118.563.001'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Env', 'Envasement', 'Envasement', 'Processus naturels d''érosion: Envasement', 'Envasement', 'Processus naturels d''érosion: Envasement', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Env'), '118.563.002'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Eng', 'Engravement', 'Engravement', 'Processus naturels d''érosion: Engravement (laves torrentielles et divagation d''une rivière)', 'Engravement', 'Processus naturels d''érosion: Engravement (laves torrentielles et divagation d''une rivière)', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Eng'), '118.563.003'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Aam', 'Avalanche apport matériaux', 'Avalanche apport matériaux', 'Processus naturels d''érosion: Avalanche (apport de matériaux non triés)', 'Avalanche', 'Processus naturels d''érosion: Avalanche (apport de matériaux non triés)', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Aam'), '118.563.004'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Evs', 'Erosion vastes surfaces', 'Erosion vastes surfaces', 'Processus naturels d''érosion:Erosion s''exerçant sur de vastes surfaces', 'Erosion vastes surfaces', 'Processus naturels d''érosion:Erosion s''exerçant sur de vastes surfaces', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Evs'), '118.563.005'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Sbe', 'Sapement berge', 'Sapement berge', 'Processus naturels d''érosion: Sapement de la berge d''un cours d''eau', 'Sapement berge', 'Processus naturels d''érosion: Sapement de la berge d''un cours d''eau', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Sbe'), '118.563.006'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Art', 'Avalanche ramonage terrain', 'Avalanche ramonage terrain', 'Processus naturels d''érosion: Avalanche-ramonage du terrain', 'Avalanche ramonage terrain', 'Processus naturels d''érosion: Avalanche-ramonage du terrain', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Art'), '118.563.007'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Ebr', 'Eboulement récent', 'Eboulement récent', 'Processus naturels d''érosion: Eboulement récent', 'Eboulement récent', 'Processus naturels d''érosion: Eboulement récent', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Ebr'), '118.563.008'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'AmL', 'Aménagements lourds', 'Aménagements lourds', 'Type de perturbation: Aménagements lourds', 'Aménagements lourds', 'Type de perturbation: Aménagements lourds', 0, '118.008'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Car', 'Carrière en roche dure', 'Carrière en roche dure', 'Aménagements lourds: Carrière en roche dure', 'Carrière en roche dure', 'Aménagements lourds: Carrière en roche dure', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Car'), '118.572.001'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Fos', 'Fossé pare-blocs', 'Fossé pare-blocs', 'Aménagements lourds: Fossé pare-blocs', 'Fossé pare-blocs', 'Aménagements lourds: Fossé pare-blocs', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Fos'), '118.572.002'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'End', 'Endiguement', 'Endiguement', 'Aménagements lourds: Endiguement', 'Endiguement', 'Aménagements lourds: Endiguement', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'End'), '118.572.003'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Ter', 'Terrassement aménagements lourds', 'Terrassement aménagements lourds', 'Aménagements lourds: Terrassement pour aménagements lourds', 'Terrassement aménagements lourds', 'Aménagements lourds: Terrassement pour aménagements lourds', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Ter'), '118.572.004'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Deb', 'Déboisement avec désouchage', 'Déboisement avec désouchage', 'Aménagements lourds: Déboisement avec désouchage', 'Déboisement avec désouchage', 'Aménagements lourds: Déboisement avec désouchage', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Deb'), '118.572.005'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Beg', 'Béton-goudron:revêtement', 'Béton-goudron:revêtement', 'Aménagements lourds: Béton, goudron-revêtement abiotique', 'Béton-goudron:revêtement', 'Aménagements lourds: Béton, goudron-revêtement abiotique', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Beg'), '118.572.006'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'GeI', 'Gestion des invasives', 'Gestion des invasives', 'Type de perturbation: Gestion des invasives', 'Gestion des invasives', 'Type de perturbation: Gestion des invasives', 0, '118.009'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Arg', 'Arrachage', 'Arrachage', 'Gestion des invasives: Arrachage', 'Arrachage', 'Gestion des invasives: Arrachage', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Arg'), '118.879.001'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Fag', 'Fauchage', 'Fauchage', 'Gestion des invasives: Fauchage', 'Fauchage', 'Gestion des invasives: Fauchage', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Fag'), '118.879.002'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Dbs', 'Débroussaillage', 'Débroussaillage', 'Gestion des invasives: Débroussaillage', 'Débroussaillage', 'Gestion des invasives: Débroussaillage', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Dbs'), '118.879.003'),
(ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION'), 'Reb', 'Recouvrement avec bâches', 'Recouvrement avec bâches', 'Gestion des invasives: Recouvrement avec bâches', 'Recouvrement avec bâches', 'Gestion des invasives:Recouvrement avec bâches', ref_nomenclatures.get_id_nomenclature('TYPE_PERTURBATION', 'Reb'), '118.879.004');