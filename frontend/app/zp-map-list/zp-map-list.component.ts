import { Component, OnInit, AfterViewInit, Input } from '@angular/core';
import { Router } from '@angular/router';

import { MapService } from '@geonature_common/map/map.service';
import { MapListService } from '@geonature_common/map-list/map-list.service';

import { DataService } from '../services/data.service';
import { StoreService } from '../services/store.service';
import { ModuleConfig } from '../module.config';

@Component({
  selector: 'pnx-zp-map-list',
  templateUrl: './zp-map-list.component.html',
  styleUrls: ['./zp-map-list.component.scss']
})
export class ZpMapListComponent implements OnInit, AfterViewInit {
  public zps;

  @Input()
  searchTaxon: string;

  public filteredData = [];
  public tabOrganism = [];

  constructor(
    public mapService: MapService,
    private _api: DataService,
    public router: Router,
    public storeService: StoreService,
    public mapListService: MapListService
  ) {}

  ngOnInit() {
    this.mapListService.idName = 'id_infos_site';
    //  pkoi c' id_infos_site et pas id_base_site?

    this._api.getZp({ id_application: ModuleConfig.id_application }).subscribe(data => {
      console.log('mon data ', data);

      this.zps = data;

      data.features.forEach(elem => {
        console.log('mes élément', elem);
        if (elem.properties.date_max === 'None') {
          elem.properties.date_max = 'Aucune visite';
        }

        this._api.getOrganisme({ id_base_site: elem.properties.id_base_site }).subscribe(organi => {
          this.tabOrganism = [];
          organi.forEach(result => {
            console.log('mes résultats ', result);
            if (result.nom_organisme === 'None') {
              result.nom_organisme = 'Aucun organisme';
            }

            this.tabOrganism.push(result.nom_organisme);
          });
          elem.properties.nom_organisme = this.tabOrganism;
        });
      });

      this.mapListService.loadTableData(data);

      this.filteredData = this.mapListService.tableData;
    });
  }

  ngAfterViewInit() {
    this.mapListService.enableMapListConnexion(this.mapService.getMap());
  }

  onEachFeature(feature, layer) {
    this.mapListService.layerDict[feature.id] = layer;

    layer.on({
      click: e => {
        this.mapListService.toggleStyle(layer);
        this.mapListService.mapSelected.next(feature.id);
      }
    });
  }

  onInfo(id_base_site) {
    this.router.navigate([`${ModuleConfig.api_url}/listVisit`, id_base_site]);
  }

  onSearchTaxon(event) {
    let trans = event.toLowerCase();
    this.filteredData = this.mapListService.tableData.filter(ligne => {
      return ligne.nom_taxon.toLowerCase().indexOf(trans) !== -1 || !trans;
    });
  }

  onSearchDate(event) {
    let trans;
    if (event !== null) {
      trans = event.toString();
    }

    this.filteredData = this.mapListService.tableData.filter(ligne => {
      return ligne.date_max.indexOf(trans) !== -1 || !trans;
    });
  }

  onSearchOrganisme(event) {
    let select = '';

    this.filteredData = this.mapListService.tableData.filter(ligne => {
      ligne.nom_organisme.forEach(el => {
        if (el.trim() === event) {
          select = el.trim();
        }
      });

      return select;
    });
  }
}
