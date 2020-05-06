import {
  Component,
  OnInit,
  AfterViewInit,
  Input,
  Output,
  EventEmitter
} from "@angular/core";
import { Router } from "@angular/router";
import { FormGroup, FormBuilder, FormControl } from "@angular/forms";

import { MapService } from "@geonature_common/map/map.service";
import { MapListService } from "@geonature_common/map-list/map-list.service";

import { DataService } from "../services/data.service";
import { StoreService } from "../services/store.service";
import { ModuleConfig } from "../module.config";

@Component({
  selector: "pnx-zp-map-list",
  templateUrl: "./zp-map-list.component.html",
  styleUrls: ["./zp-map-list.component.scss"]
})
export class ZpMapListComponent implements OnInit, AfterViewInit {
  public zps;

  @Input()
  searchTaxon: string;

  public filteredData = [];
  public tabOrganism = [];
  public taxonForm = new FormControl();
  public filtreForm: FormGroup;
  public paramApp = {
    id_application: ModuleConfig.ID_MODULE,
    id_area_type: ModuleConfig.id_type_commune
  };

  public actualDate;
  public actualTaxonNameId;
  public tabCom = [];
  @Output()
  onDeleteFiltre = new EventEmitter<any>();

  constructor(
    public mapService: MapService,
    private _api: DataService,
    public router: Router,
    public storeService: StoreService,
    public mapListService: MapListService,
    private _fb: FormBuilder
  ) {}

  ngOnInit() {
    this.mapListService.idName = "id_infos_site";
    this.storeService.initialize();
    this.filtreForm = this._fb.group({
      filtreYear: null,
      filtreOrga: null,
      filtreCom: null
    });

    this.onChargeList(this.paramApp);

    // Year
    this.filtreForm.controls.filtreYear.valueChanges
      .filter(input => input !== null && input.toString().length === 4)
      .subscribe(year => {
        this.onSearchDate(year);
      });

    this.filtreForm.controls.filtreYear.valueChanges
      .filter(input => !input || input === null || input === "")
      .subscribe(year => {
        this.onDeleteParams("year", this.actualDate);
        this.onDeleteFiltre.emit();
        this.onDelete();
      });

    // Organism
    this.filtreForm.controls.filtreOrga.valueChanges
      .filter(select => !select || select !== null)
      .subscribe(org => {
        this.onSearchOrganisme(org);
      });

    this.filtreForm.controls.filtreOrga.valueChanges
      .filter(input => !input || input === null)
      .subscribe(org => {
        this.onDeleteParams("organisme", org);
        this.onDeleteFiltre.emit();
        this.onDelete();
      });

    // Municipality
    this.filtreForm.controls.filtreCom.valueChanges
      .filter(select => !select || select !== null)
      .subscribe(com => {
        this.onSearchCom(com);
      });

    this.filtreForm.controls.filtreCom.valueChanges
      .filter(input => !input || input === null)
      .subscribe(com => {
        this.onDeleteParams("commune", com);
        this.onDeleteFiltre.emit();
        this.onDelete();
      });
  }

  ngAfterViewInit() {
    this.mapListService.enableMapListConnexion(this.mapService.getMap());

    this._api.getOrganisme()
      .subscribe(elem => {
        elem.forEach(orga => {
          if (this.tabOrganism.indexOf(orga.nom_organisme) === -1) {
            this.tabOrganism.push(orga.nom_organisme);
          }
          this.tabOrganism.sort((a, b) => {
            return a.localeCompare(b);
          });
        });
      });

    let params = {id_area_type: this.storeService.sftConfig.id_type_commune};
    this._api.getCommune(ModuleConfig.ID_MODULE, params)
      .subscribe(info => {
        info.forEach(com => {
          if (this.tabCom.indexOf(com.nom_commune) === -1) {
            this.tabCom.push(com.nom_commune);
          }
          this.tabCom.sort((a, b) => {
            return a.localeCompare(b);
          });
        });
      });
  }

  onChargeList(param) {
    this._api.getZp(this.storeService.queryString).subscribe(data => {
      this.zps = data;
      this.mapListService.loadTableData(data);
      this.filteredData = this.mapListService.tableData;
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
    this.router.navigate([
      `${ModuleConfig.MODULE_URL}/sites`,
      id_base_site
    ]);
  }

  onSearchDate(event) {
    this.onSetParams("year", event);
    this.onChargeList({
      id_application: ModuleConfig.ID_MODULE,
      year: event
    });
    this.actualDate = event;
  }

  onSearchOrganisme(event) {
    this.onSetParams("organisme", event);
    this.onChargeList({
      id_application: ModuleConfig.ID_MODULE,
      organisme: event
    });
  }

  onTaxonChanged(event) {
    this.onSetParams("cd_nom", event.item.cd_nom);
    this.actualTaxonNameId = event.item.cd_nom;
    this.onChargeList({
      id_application: ModuleConfig.ID_MODULE,
      cd_nom: event.item.cd_nom
    });
  }

  onSearchCom(event) {
    this.onSetParams("commune", event);
    this.onChargeList({
      id_application: ModuleConfig.ID_MODULE,
      commune: event
    });
  }

  onDelete() {
    this.onChargeList(this.paramApp);
  }

  onSetParams(param: string, value) {
    // Add filter query string to download data
    this.storeService.queryString = this.storeService.queryString.set(
      param,
      value
    );
  }

  onDeleteParams(param: string, value) {
    // Remove filter query string to download data
    this.storeService.queryString = this.storeService.queryString.delete(
      param,
      value
    );
  }
}
