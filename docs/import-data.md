# Importer des données dans Suivi Flore Territoire

Plusieurs scripts sont disponibles pour importer les données manipulées dans le module SFT. Les données sources à importer doivent être fourni au format CSV (encodage UTF-8) ou Shape en fonction du type de données
 suivantes :
 - taxons (`import_taxons.sh`) : CSV
 - nomenclatures (`import_nomenclatures.sh`) : CSV
 - mailles (`import_meshes.sh`) : Shape
 - sites (`import_sites.sh`) : Shape
 - visites (`import_visits.sh`) : CSV

Chacun de ces scripts est disponibles dans le dossier `bin/`.

Avant de lancer les scripts, il est nécessaires de correctement les paramètrer à l'aide du fichier `config/imports_settings.ini`. Une section de paramètres concerne chacun d'entre eux. Ces paramètres permettent entre autre d'indiquer :
 - le chemin et le nom vers le fichier source (CSV ou Shape)
 - le chemin et le nom du fichier de log où les informations affichées durant son execution seront enregistrées
 - le nom des tables temporaires dans lesquelles les données sources sont stockées avant import dans les tables de GeoNature. Elles sont toutes crées dans le schema du module.
 - pour les fichiers source de type Shape (mailles, sites), les noms des champs des attributs des objets géographiques
 - pour les fichiers source de type CSV (visites), les noms des colonnes

 Enfin, pour chaque import le paramètre *import_date* doit être correctement renseigné avec une date au format `yyyy-mm-dd` distincte. Cette date permet d'associer dans la base de données, les mailles, sites, visites mais aussi utilisateurs (=`role`) et organismes à l'import courant.
 Laisser en commentaire dans le fichier `imports_settings.ini` les dates utilisées pour chaque import.
 L'utilisation de la date courante n'est pas obligatoire. Vous êtes libre de choisir celle qui vous convient le mieux.

## Format des données
Voici le détail des champs des fichiers CSV ou Shape attendus par défaut :

### Taxons (CSV)

Description des colonnes attendues dans le fichier CSV contenant la liste des taxons suivis dans SFT :

 - **cd_nom** : code TaxRef du nom du taxon suivi dans SFT
 - **cd_ref** : code TaxRef du nom de référence du taxon suivi dans SFT
 - **name** : nom français à utiliser lors de l'affichage des listes d'autocomplétion.
 - **comment** : commentaire associé au nom

### Nomenclatures (CSV)

Description des colonnes attendues dans le fichier CSV contenant la liste des nomenclatures utilisées dans SFT (les types de perturbation des sites) :

 - **type_nomenclature_code** : code du type de nomeclature à laquelle correspond cette valeur de nomenclature. Ex. : *TYPE_PERTURBATION*.
 - **cd_nomenclature** : code de la nomenclature. Ex. : *GeF*.
 - **mnemonique** : libellé court de la nomenclature. Ex. *Gestion par le feu*.
 - **label_default** : libellé par défaut de la nomenclature. Ex. *Gestion par le feu*.
 - **definition_default** : définition courte par défaut de la nomenclature. Ex. *Type de perturbation : gestion par le feu*.
 - **label_fr** : libellé en français de la nomenclature. Ex. *Gestion par le feu*.
 - **definition_fr** : définition courte en français de la nomenclature. Ex. *Type de perturbation : gestion par le feu*.
 - **cd_nomenclature_broader** : code de la nomenclature parente si elle existe. Utiliser 0 si la nomenclature n'pas de parente.
 - **hierarchy**: hiérarchie de code numérique sur 3 chiffres séparés par des points. Doit débuter par un point. Ex. *.001* pour une valeur n'ayant pas de parent ou *.001.002* pour la seconde valeur *.002* de la valeur parente *.001*.

### Mailles (Shape)

Description des paramètres de configuration permettant d'indiquer les noms des champs utilisés dans les attributs des objets géographiques du fichier Shape pour les mailles des sites :

 - **meshes_name_column** : nom du champ dans les attributs des objets géographiques du fichier Shape contenant le code de la maille.

Autres paramètres :
- **meshes_geom_column** : nom du champ contenant la géométrie de la maille dans la table temporaire créé dans Postgresql. Ce champ n'a pas à apparaitre dans les attributs des objets géographique. Par défaut, l'utilitaire employé par le script (*shp2pgsql*) créé une colonne ayant pour libellé *geom* en se basant sur les infos géographiques du fichier Shape.
- **meshes_type_column** : nom du champ indiquant le type de maille. La présence de ce champ n'est pas obligatoire dans les attributs des objets géographiques du fichier Shape. Par défaut la valeur du parametre `meshes_code` du fichier `settings.default.ini` est utilisée. Ce dernier paramètre doit correspondre au paramètre de config `id_type_maille`. Pour l'instant l'interface du module supporte seulement un unique type de maille . Du coup, même si des mailles d'autres dimenssions sont utilisées il faut les associer à ce type maille... Voir le ticket [#74](https://github.com/PnX-SI/gn_module_suivi_flore_territoire/issues/74).
- **meshes_action_column** : nom du champ indiquant le type d'action à effectuer sur l'objet géographique. La présence de ce champ n'est pas obligatoire dans les attributs des objets géographiques du fichier Shape. Valeurs possibles : `A` = ajout (par défaut), `M` = modification et `S` = suppression.
 - **meshes_tmp_table** : nom de la table temporaire contenant les mailles créée dans Postgresql.
 - **meshes_source** : permet d'indiquer l'organisme fournissant la géométrie des mailles.

### Sites (Shape)

Le fichier Shape fournissant les contours des sites devrait contenir des géométries qui recoupent uniquement les mailles concernnées pour chaque site. Leur géométrie devrait avoir un contour au moins légérement inférieur aux mailles qui le composent.

En effet, un *trigger* en base de données réalise automatiquement le lien entre la géométrie d'un site et les mailles qui le composent à l'aide de la fonction Postgis *st_intersect*. Il faut donc éviter les géométries de site qui collent au contour des mailles car si 2 sites dans ce cas sont en contact au travers d'une ou plusieurs mailles, celles-ci vont se retrouver liées aux 2 sites.

Description des paramètres de configuration permettant d'indiquer les noms des champs utilisés dans les attributs des objets géographiques du fichier Shape pour les sites :

 - **site_code_column** : nom du champ contenant le code du site.
 - **site_taxon_column** : nom du champ contenant le code TaxRef du nom (*cd_nom*) du taxon étudié sur ce site.
 - **site_desc_column** : nom du champ contenant la description du site.
 - **site_action_column** : nom du champ indiquant le type d'action à effectuer sur l'objet géographique (= le site). La présence de ce champ n'est pas obligatoire dans les attributs des objets géographiques du fichier Shape. Valeurs possibles : `A` = ajout (par défaut), `M` = modification et `S` = suppression.

Autres paramètres :
 - **site_geom_column** : nom du champ contenant la géométrie du site dans la table temporaire créé dans Postgresql. Ce champ n'a pas à apparaitre dans les attributs des objets géographique. Par défaut, l'utilitaire employé par le script (*shp2pgsql*) créé une colonne ayant pour libellé *geom* en se basant sur les infos géographiques du fichier Shape.
 - **sites_tmp_table** : nom de la table temporaire contenant les sites créée dans Postgresql.

### Visites (CSV)
Description des colonnes attendues dans le fichier CSV contenant la liste des visites. Les nom des colonnes peuvent modifié à l'aide des paramètres du fichier de configuration indiqués ici entre parenthèses :

 - **idzp** (*visits_column_id*) : identifiant ou code alphanumérique du site où a eu lieu la visite. Le même site référencé dans 2 imports distincts doit avoir le même identifiant dans ce champ. Deux sites différents ne doivent en aucun cas posséder le même identifiant.
 - **cd25m** (*visits_column_meshe*) : code de la maille où a eu lieu la visite.
 - **observateu** (*visits_column_observer*) : liste des observateurs au format "NOM Prénom" séparés par des pipes "|". L'ordre doit correspondre à l'ordre des organismes du champ *organimes*.
 - **organismes** (*visits_column_organism*) : liste des organimes séparés par des pipes "|". L'ordre doit correspondre à l'ordre des observateurs du champ *observateu*.
 - **date_deb** (*visits_column_date_start*) : date de début de la visite.
 - **date_fin** (*visits_column_date_end*) : date de fin de la visite. Elle sera identique à *date_deb* si la visite a eu lieu sur un seul jour.
 - **presence** (*visits_column_status*) : permet d'indiquer la presence (pr), l'absence (ab) ou la non observation (na) du taxon sur la maille.

 Autres paramètres :
 - **visits_table_tmp_visits** : nom de la table temporaire contenant les visites par maille.
 - **visits_table_tmp_has_observers** : nom de la table temporaire contenant les liens entre visites et observateurs.
 - **visits_table_tmp_observers** : nom de la table temporaire contenant les prénoms nom des observateurs et leur organisme.


## Options des scripts d'import

Il possèdent tous les options suivantes :
 - `-h` (`--help`) : pour afficher l'aide du script.
 - `-v` (`--verbosity`) : le script devient verbeux est affiche plus de messages concernant le travail qu'il accomplit.
 - `-x` (`--debug`) : le mode débogage de Bash est activé.
 - `-c` (`--config`) : permet d'indiquer le chemin vers un fichier de configuration spécifique. Par défaut, c'est le fichier `config/settings.ini` qui est utilisé.
 - `-d` (`--delete`) : chacun des imports peut être annulé avec cette option. Attention, il faut s'assurer que le script est correctement configuré avec les paramètres correspondant à l'import que vous souhaitez annuler.

## Procédure

Afin que les triggers présents sur les tables soient déclenchés dans le bon ordre et que les scripts trouvent bien les données de référence dont ils ont besoin, il est obligatoire de lancer les scripts dans cet ordre :
 1. taxons : `import_taxons.sh`
 2. nomenclatures : `import_nomenclatures.sh`
 3. mailles : `import_meshes.sh`
 4. sites : `import_sites.sh`
 5. visites : `import_visits.sh`

La désinstallation des données importées se fait dans le sens inverse. Il faut commencer par les visites puis passer aux sites...

**ATTENTION :** concernant la désinstallation, il s'agit d'une manipulation délicate à utiliser principalement sur une base de données de test ou lors du développement du module. En production, nous vous conseillons fortement d'éviter son utilisation. Si vous y êtes contraint, veuillez sauvegarder votre base de données auparavant.

Pour lancer un script, ouvrir un terminal et se placer dans le dossier `bin/` du module SFT.
Ex. pour lancer le script des visites :
 - en importation : `./import_visits.sh`
 - en suppression des imports précédents : `./import_visits.sh -d`

Une fois l'ensemble des imports réalisés vous pouvez vérifier les données présentent dans la base à l'aide de l'interface du module mais aussi via le script suivant : `./import_checking.sh`


## Notes et aides diverses

### Lignes dupliquées dans la liste d'auto-complétion des taxons

Dans les versions antérieures à v2.4.0 de GeoNature, des doublons pouvaient apparaitre dans les listes d'auto-complétion des taxons. La requête ci-dessous permet de nettoyer "*taxonomie.vm_taxref_list_forautocomplete*" qui dans les version inférieures à v2.4.0 est une table et non une vue matérialisée :

```sql
WITH tax_list AS (
    SELECT id_liste AS id
    FROM taxonomie.bib_listes
    WHERE nom_liste = '<replace-by-taxon-list-name>'
    ORDER BY id_liste ASC
    LIMIT 1
)
DELETE FROM taxonomie.vm_taxref_list_forautocomplete AS vtlf1
USING taxonomie.vm_taxref_list_forautocomplete AS vtlf2, tax_list
WHERE vtlf1.ctid < vtlf2.ctid
	AND vtlf1.cd_nom = vtlf2.cd_nom
	AND vtlf1.cd_ref = vtlf2.cd_ref
	AND vtlf1.id_liste = vtlf2.id_liste
	AND vtlf1.id_liste = (SELECT id FROM tax_list);
```

### Lister les sites possédant des mailles communes

```sql
SELECT DISTINCT tbs0.id_base_site, tbs0.base_site_code
FROM gn_monitoring.cor_site_area AS csa0
	INNER JOIN gn_monitoring.t_base_sites AS tbs0
			ON (tbs0.id_base_site = csa0.id_base_site)
WHERE id_area IN (
	SELECT csa.id_area
	FROM gn_monitoring.cor_site_area AS csa
		INNER JOIN ref_geo.l_areas AS la
			ON (csa.id_area = la.id_area)
	WHERE la.id_type = (SELECT id_type FROM ref_geo.bib_areas_types WHERE type_code = 'M25m')
	GROUP BY csa.id_area
	HAVING COUNT(csa.id_area) > 1
);
```

### Lister des mailles non comprisent entièrement dans leur site

Au préalable, exécuter le SQL permettant d'ajouer la fonction *st_dilate* dont le code est proposé sur [[https://github.com/iboates/ST_Dilate|le dépôt Github iboates/ST_Dilate]].

Exemple, liste des mailles non comprisent entièrement dans la géométrie de leur site pour les sites 5, 13, 128 et 176 :
```sql
SELECT DISTINCT tbs.id_base_site, tbs.base_site_code, tbs.geom, la.geom, la.id_area
FROM gn_monitoring.t_base_sites AS tbs
	INNER JOIN gn_monitoring.cor_site_area AS csa
		ON (tbs.id_base_site = csa.id_base_site)
	INNER JOIN ref_geo.l_areas AS la
		ON (csa.id_area = la.id_area)
	WHERE la.id_type = (SELECT id_type FROM ref_geo.bib_areas_types WHERE type_code = 'M25m')
	AND tbs.id_base_site IN (5, 13, 128, 176)
	AND NOT public.ST_ContainsProperly(st_dilate(tbs.geom_local, 1.1), public.st_transform(la.geom, 2154)) ;
```
