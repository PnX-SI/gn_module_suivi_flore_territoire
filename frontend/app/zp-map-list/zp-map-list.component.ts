import { Component, OnInit, AfterViewInit } from "@angular/core";
import { FormControl } from "@angular/forms";
import { AppConfig } from "@geonature_config/app.config";
import { MapService } from "@geonature_common/map/map.service";
import { maille } from "./mailleGeojson";
import { DataService } from "../services/data.service";
import { HttpClient, HttpParams } from "@angular/common/http";
import { Router } from '@angular/router';
import { StoreService} from '../services/store.service';
import { MapListService } from '@geonature_common/map-list/map-list.service';
import { DataFormService} from "@geonature_common/form/data-form.service"; 



@Component({
  selector: "pnx-zp-map-list",
  templateUrl: "./zp-map-list.component.html",
  styleUrls: ['./zp-map-list.component.scss'],

})
export class ZpMapListComponent implements OnInit, AfterViewInit {
    public zps;
    public currentZp = {};
    public id_ZP;

  
   public columns = [
       { name: 'Identifiant', prop:'id_infos_site' },
       { name: 'Nomenclature', prop: 'cd_nom'}, 
              // { name: 'Actions' }
     ];
  constructor(public mapService: MapService, public _api: DataService, public router: Router, public storeService: StoreService,
    public mapListService:MapListService, public dataFormService: DataFormService
  ) {}

  
  ngOnInit() {
      this.mapListService.idName = 'id_infos_site';
      let nomTaxon;  
      this._api.getZp().subscribe(data => {
  
      this.zps = data; 
      console.log("data ici", data);
  
      this.mapListService.loadTableData(data);

      data.features.forEach(nomen => {
        this.dataFormService.getTaxonInfo(nomen.properties.cd_nom).subscribe(taxon => {
                  nomTaxon = taxon.nom_valide;  
                  nomen.properties.cd_nom = nomTaxon;
                 
        }) 
              

     });
    });


  }

  ngAfterViewInit() {
    this.mapListService.enableMapListConnexion(this.mapService.getMap());

  }

  onEachFeature(feature, layer) {
    this.mapListService.layerDict[feature.id] = layer;
    layer.on({
        click: (e) => {
            // toggle style
            this.mapListService.toggleStyle(layer);
            // observable
            this.mapListService.mapSelected.next(feature.id);
            // open popup
            // layer.bindPopup(feature.properties.leaflet_popup).openPopup();
        }
    });

  }

  onInfo(id_base_site) {
    this.router.navigate(['suivi_flore_territoire/listVisit',  id_base_site])
    
  }
}
