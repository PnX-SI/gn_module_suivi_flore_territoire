import { Component, OnInit } from "@angular/core";
import { FormControl } from "@angular/forms";
import { AppConfig } from "@geonature_config/app.config";
import { MapService } from "@geonature_common/map/map.service";
import { maille } from "./mailleGeojson";
import { DataService } from "./services/data.service";
import { HttpClient, HttpParams } from "@angular/common/http";

@Component({
  selector: "pnx-test",
  templateUrl: "./test.component.html"
})
export class TestComponent implements OnInit {
  public zps;
  public currentZp = {};

  public myStylePresent = {
    color: "#ff7800",
    fill: true,
    fillOpacity: 0.2,
    weight: 3
  };

  public myStyleAbsent = {
    color: "#228b22",
    fill: true,
    fillOpacity: 0.2,
    weight: 3
  };
  constructor(public mapService: MapService, public _api: DataService) {}

  ngOnInit() {
    this._api.getZp().subscribe(data => {
      console.log(data);
      this.zps = data;
    });
  }

  onEachFeature(feature, layer) {
    layer.on({
      click: event => {
        console.log(feature.properties);
        this.currentZp = feature.properties;
        console.log(this.currentZp);
      }
    });
  }
}
