import { Component, OnInit, AfterViewInit, Input, Output, EventEmitter } from '@angular/core';
import { Router } from '@angular/router';
import { FormGroup, FormBuilder, Validators, FormControl } from '@angular/forms';

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
  public taxonForm = new FormControl();
  public yearForm = new FormControl();
  public organForm = new FormControl();
  public paramApp = {
    id_application: ModuleConfig.id_application
  };

  @Output()
  onDeleteFiltre = new EventEmitter<any>();

  constructor(
    public mapService: MapService,
    private _api: DataService,
    public router: Router,
    public storeService: StoreService,
    public mapListService: MapListService
  ) {}

  ngOnInit() {
    this.mapListService.idName = 'id_infos_site';

    this.onChargeList(this.paramApp);

    this.yearForm.valueChanges
      .filter(input => input !== null && input.toString().length === 4)
      .subscribe(year => {
        this.onSearchDate(year);
      });

    this.yearForm.valueChanges
      .filter(input => !input || input === null || input === '')
      .subscribe(year => {
        this.onDeleteFiltre.emit();
        this.onDelete();
      });

    this.organForm.valueChanges
      .filter(select => !select || select !== null)
      .subscribe(org => this.onSearchOrganisme(org));

    this.organForm.valueChanges
      .filter(input => !input || input === null || input === 'all')
      .subscribe(org => {
        this.onDeleteFiltre.emit();
        this.onDelete();
      });
  }

  onChargeList(param) {
    this._api.getZp(param).subscribe(data => {
      this.zps = data;

      this.mapListService.loadTableData(data);
      this.filteredData = this.mapListService.tableData;
    });
  }

  ngAfterViewInit() {
    this.mapListService.enableMapListConnexion(this.mapService.getMap());

    this._api.getOrganisme().subscribe(orga => {
      this.tabOrganism.push(orga.nom_organisme);
    });
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

  onSearchDate(event) {
    this.onChargeList({
      id_application: ModuleConfig.id_application,
      year: event
    });
  }

  onDelete() {
    this.onChargeList(this.paramApp);
  }

  onSearchOrganisme(event) {
    console.log('mon event ', event);

    this.onChargeList({ id_application: ModuleConfig.id_application, organisme: event });
  }

  onTaxonChanged(event) {
    this.onChargeList({ id_application: ModuleConfig.id_application, cd_nom: event.item.cd_nom });
  }
}
