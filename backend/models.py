from sqlalchemy import ForeignKey
from sqlalchemy.ext.associationproxy import association_proxy

from geonature.utils.env import DB
from geonature.utils.utilssqlalchemy import (
        serializable,
        geoserializable,
        GenericQuery
)
from geonature.core.gn_monitoring.models import TBaseSites, TBaseVisits, corVisitObserver
from geonature.core.ref_geo.models import LAreas
from pypnnomenclature.models import TNomenclatures
from geonature.core.users.models import TRoles

@serializable
@geoserializable
class TInfoSite(DB.Model):
    '''
    Modèle d'une ZP
    '''
    __tablename__ = 't_infos_site'
    __table_args__ = {'schema': 'pr_monitoring_flora_territory'}

    id_infos_site = DB.Column(DB.Integer, primary_key=True)
    # fk gn_monitoring.base_site
    id_base_site = DB.Column(
        DB.Integer,
        ForeignKey(TBaseSites.id_base_site)
    )
    base_site = DB.relationship(TBaseSites)
    geom = association_proxy('base_site', 'geom')
    cd_nom = DB.Column(DB.Integer)

    def get_geofeature(self, recursif=True):
        return self.as_geofeature(
            'geom',
            'id_infos_site',
            recursif
        )

@serializable
# @geoserializable
class CorVisitGrids(DB.Model):
    '''
    Corespondance entre une maille et une visite
    '''
    __tablename__ = 'cor_visit_grid'
    __table_args__ = {'schema': 'pr_monitoring_flora_territory'}

    id_area = DB.Column(
      DB.Integer,
      ForeignKey(LAreas.id_area),
      primary_key=True
      )
    id_base_visit = DB.Column(
      DB.Integer,
      ForeignKey(TBaseVisits.id_base_visit),
      primary_key=True
    )
    presence = DB.Column(DB.Boolean)


@serializable
@geoserializable
class CorVisitPerturbation(DB.Model):
    '''
    Corespondance entre une maille et une visite
    '''
    __tablename__ = 'cor_visit_perturbation'
    __table_args__ = {'schema': 'pr_monitoring_flora_territory'}

    id_base_visit = DB.Column(
      DB.Integer,
      ForeignKey(TBaseVisits.id_base_site),
      primary_key=True,
      )
    id_nomenclature_perturbation = DB.Column(
      DB.Integer,
      ForeignKey(TNomenclatures.id_nomenclature),
      primary_key=True
      )


@serializable
class TVisiteSFT(TBaseVisits):
    '''
    Visite sur une ZP
    et corespondance avec ses mailles
    '''
    __tablename__ = 't_base_visits'
    __table_args__ = {
        'schema': 'gn_monitoring',
        'extend_existing': True
        }
    cor_visit_grid = DB.relationship(
        'CorVisitGrids',
        primaryjoin=(
            CorVisitGrids.id_base_visit == TBaseVisits.id_base_visit
        ),
        foreign_keys=[
            CorVisitGrids.id_base_visit,
        ]
    )
    cor_visit_perturbation = DB.relationship(
        'CorVisitPerturbation',
        primaryjoin=(
            CorVisitPerturbation.id_base_visit == TBaseVisits.id_base_visit
        ),
        foreign_keys=[
            CorVisitPerturbation.id_base_visit,
        ]
    )




