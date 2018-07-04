import { Component, OnInit, AfterViewInit } from "@angular/core";
import { FormControl } from "@angular/forms";
import { AppConfig } from "@geonature_config/app.config";
import { MapService } from "@geonature_common/map/map.service";
import { maille } from "./mailleGeojson";
import { HttpClient, HttpParams } from "@angular/common/http";

@Component({
  selector: "pnx-view-test",

  templateUrl: "./view-test.component.html",
  styleUrls: ["./view-test.component.scss"]
})
export class ViewTestComponent implements OnInit, AfterViewInit {
  public myGeojson;
  public comptePresent;
  public compteAbsent;
  public myLayers;

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
  constructor(public mapService: MapService) {}

  ngOnInit() {
    // console.log(this.mapService.map);
    // console.log(this.myGeojson);
    // this.mapService.getZP().subscribe(
    //   data => {
    //     this.myGeojson = data.values; 
    //   }
    // );
    
    // this._http
    //   .get<any>(`${AppConfig.API_ENDPOINT}/suivi_flore_territoire/sites`)
    //   .subscribe(data => {
    //     console.log("INITTTT");

    //     console.log(data);
    //   });
  }

  ngAfterViewInit() {
    this.mapService.map.doubleClickZoom.disable();
  }

  afficheMaille() {
    console.log(
      "Il y en a " + this.comptePresent + " mailles présentes d'espèce"
    );
    console.log(
      "Il y en a " + this.compteAbsent + " mailles absentes d'espèce"
    );
    console.log(
      "Il en reste " +
        (this.myGeojson.features.length -
          this.compteAbsent -
          this.comptePresent) +
        " maille(s) pas encore visitées"
    );
  }

  onEachFeature(feature, layer) {
    this.myLayers[feature.properties.ID] = layer;
    //  on précise que chaque élément de l'objet myLayers correspond à un layer (on y accède via son id)
    layer.on({
      click: event1 => {
        layer.setStyle(this.myStylePresent);

        if (feature.state == 2) {
          this.compteAbsent -= 1;
          this.comptePresent += 1;
        } else if (feature.state == 1) {
          this.comptePresent += 0;
        } else {
          this.comptePresent += 1;
        }
        feature.state = 1;
        layer.bindPopup("espèce présente dans maille!");
        this.afficheMaille();
      },

      contextmenu: event2 => {
        layer.setStyle(this.myStyleAbsent);
        if (feature.state == 1) {
          this.comptePresent -= 1;
          this.compteAbsent += 1;
        } else if (feature.state == 2) {
          this.compteAbsent += 0;
        } else {
          this.compteAbsent += 1;
        }
        feature.state = 2;
        layer.bindPopup("espèce absente dans maille");
        this.afficheMaille();
      },

      dblclick: event3 => {
        layer.setStyle(this.mapService.originStyle);
        if (feature.state == 1) {
          this.comptePresent -= 1;
        } else if (feature.state == 2) {
          this.compteAbsent -= 1;
        }
        feature.state = 0;
        layer.bindPopup("maille pas visitée");
        this.afficheMaille();
      }
    });
  }

  getState() {
    console.log(this.myLayers);
  }
}
