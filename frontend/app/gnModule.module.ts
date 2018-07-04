import { NgModule } from "@angular/core";
import { GN2CommonModule } from "@geonature_common/GN2Common.module";
import { CommonModule } from "@angular/common";
import { Routes, RouterModule } from "@angular/router";
import { ViewTestComponent } from "./view-test/view-test.component";
import { TestComponent } from "./test.component";
import { HttpClient } from "@angular/common/http";
import { DataService } from "./services/data.service";
import { HttpClientModule } from "@angular/common/http";
import { StoreService } from "./services/store.service";
import { AfficheMailleComponent } from './afficheMaille.component';  
import { OcctaxFormService } from '../../../GeoNature/contrib/occtax/frontend/app/occtax-map-form/form/occtax-form.service';


// my module routing
const routes: Routes = 
[{ path: "", component: TestComponent},
 {path: "afficheMaille/:id", component: AfficheMailleComponent},

  
 ];

@NgModule({
  declarations: [TestComponent, AfficheMailleComponent ],
  imports: [
    GN2CommonModule,
    RouterModule.forChild(routes),
    HttpClientModule,
    CommonModule
  ],
  providers: [HttpClient, DataService, StoreService, OcctaxFormService],
  bootstrap: []
})

export class GeonatureModule {

}
