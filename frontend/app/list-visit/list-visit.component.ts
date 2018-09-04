import { Component, OnInit, ViewChild, AfterViewInit } from '@angular/core';
import { FormGroup } from '@angular/forms';
import { Router, ActivatedRoute } from '@angular/router';

import { MapListService } from '@geonature_common/map-list/map-list.service';
import { MapService } from '@geonature_common/map/map.service';
import { GeojsonComponent } from '@geonature_common/map/geojson/geojson.component';

import { DataService } from '../services/data.service';

import { StoreService } from '../services/store.service';
import { ModuleConfig } from '../module.config';

@Component({
  selector: 'pnx-list-visit',
  templateUrl: 'list-visit.component.html',
  styleUrls: ['./list-visit.component.scss']
})
export class ListVisitComponent implements OnInit, AfterViewInit {
  public zps;
  public nomTaxon;
  public currentZp = {};
  public idSite;
  public visitGrid: FormGroup;
  public idVisit;
  public rows = [];

  public nomCommune;

  @ViewChild('geojson')
  geojson: GeojsonComponent;

  constructor(
    public mapService: MapService,
    public _api: DataService,
    public activatedRoute: ActivatedRoute,
    public storeService: StoreService,
    public router: Router,
    public mapListService: MapListService
  ) {}

  ngOnInit() {
    this.idSite = this.activatedRoute.snapshot.params['idSite'];

    this.storeService.queryString = this.storeService.queryString.set('id_base_site', this.idSite);

    this._api
      .getCommune(this.idSite, { id_area_type: this.storeService.sftConfig.id_type_commune })
      .subscribe(commune => {
        commune.forEach(name => {
          this.nomCommune = name.area_name;
        });
      });

    this._api
      .getMaille(this.idSite, { id_area_type: this.storeService.sftConfig.id_type_maille })
      .subscribe(nbMaille => {
        this.storeService.total = nbMaille.features.length;
      });

    const param3 = this._api.getVisits({ id_base_site: this.idSite }).subscribe(data => {
      data.forEach(visit => {
        let fullName;
        visit.observers.forEach(obs => {
          fullName = obs.nom_role + ' ' + obs.prenom_role;
        });
        visit.observers = fullName;
        let pres = 0;
        let abs = 0;

        visit.cor_visit_grid.forEach(maille => {
          if (maille.presence) {
            pres += 1;
          } else {
            abs += 1;
          }
        });

        visit.state = pres + 'P / ' + abs + 'A ';
      });

      this.rows = data;
    });
  }

  ngAfterViewInit() {
    this.mapService.map.doubleClickZoom.disable();

    const parametre = {
      id_base_site: this.idSite,
      id_application: ModuleConfig.id_application
    };

    this._api.getZp(parametre).subscribe(data => {
      this.nomTaxon = data.features[0].properties.nom_taxon;

      this.zps = data;
      this.geojson.currentGeoJson$.subscribe(currentLayer => {
        this.mapService.map.fitBounds(currentLayer.getBounds());
      });
    });
  }

  onEachFeature(feature, layer) {
    this.currentZp = feature.id;
  }

  onEdit(id_visit) {
    this.router.navigate([`${ModuleConfig.api_url}/editVisit`, this.idSite, 'visit', id_visit]);
  }

  onInfo(id_visit) {
    this.router.navigate([`${ModuleConfig.api_url}/infoVisit`, id_visit]);
  }

  onAdd() {
    this.router.navigate([`${ModuleConfig.api_url}/editVisit`, this.idSite]);
  }
}
