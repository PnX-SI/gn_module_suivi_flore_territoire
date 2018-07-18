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
import { DetailVisitComponent } from "./detail-visit/detail-visit.component";
import { ZpMapListComponent } from "./zp-map-list/zp-map-list.component";
import { ListVisitComponent } from "./list-visit/list-visit.component";
import { EditVisitComponent } from "./edit-visit/edit-visit.component";
import { AddVisitComponent } from "./add-visit/add-visit.component";

// my module routing
const routes: Routes = 
[{ path: "", component: ZpMapListComponent},
 { path: "listVisit/:idSite", component: ListVisitComponent},
 {path: "addVisit/:idSite", component: AddVisitComponent},
 {path: "infoVisit/:idVisit", component: DetailVisitComponent },
 {path: "editVisit/:idVisit", component: EditVisitComponent}

  
 ];

@NgModule({
  declarations: [ZpMapListComponent, AddVisitComponent, ListVisitComponent, DetailVisitComponent, EditVisitComponent ],
  imports: [
    GN2CommonModule,
    RouterModule.forChild(routes),
    HttpClientModule,
    CommonModule
  ],
  providers: [HttpClient, DataService, StoreService],
  bootstrap: []
})

export class GeonatureModule {

}
