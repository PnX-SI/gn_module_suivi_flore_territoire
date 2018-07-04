import { Component, OnInit } from "@angular/core";
import { FormControl } from "@angular/forms";
import { AppConfig } from "@geonature_config/app.config";
import { MapService } from "@geonature_common/map/map.service";
import { maille } from "./mailleGeojson";
import { DataService } from "./services/data.service";
import { HttpClient, HttpParams } from "@angular/common/http";
import { Router } from '@angular/router';
import { StoreService} from './services/store.service';


@Component({
  selector: "pnx-test",
  templateUrl: "./test.component.html"
})
export class TestComponent implements OnInit {
    public zps;
    public currentZp = {};

   
  constructor(public mapService: MapService, public _api: DataService, public route: Router, public storeService: StoreService) {}

  
  ngOnInit() {
    this._api.getZp().subscribe(data => {
      this.zps = data;
      console.log(data);
     
      
    });
  }

  

  onEachFeature(feature, layer) {
    layer.on({
      click: event => {
        this.currentZp = feature.properties;
      //  console.log(feature.properties.id_infos_site);
        
      
    
        this.route.navigate(['suivi_flore_territoire/afficheMaille', feature.properties.id_base_site]);

      }
    });
  }
}
