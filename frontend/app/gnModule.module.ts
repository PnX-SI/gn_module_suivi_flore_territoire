import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClientXsrfModule } from '@angular/common/http';
import { Routes, RouterModule } from '@angular/router';
import { HttpClient } from '@angular/common/http';

import { GN2CommonModule } from '@geonature_common/GN2Common.module';

import { DataService } from './services/data.service';
import { StoreService } from './services/store.service';
import { BreadcrumbsComponent } from './components/breadcrumbs/breadcrumbs.component';
import { ZpMapListComponent } from './zp-map-list/zp-map-list.component';
import { ListVisitComponent } from './list-visit/list-visit.component';
import { DetailVisitComponent } from './detail-visit/detail-visit.component';
import { FormVisitComponent } from './form-visit/form-visit.component';

// Module routing and breadcrumbs
const routes: Routes = [
  {
    path: '',
    redirectTo: 'sites',
    pathMatch: 'full',
  },
  {
    path: 'sites',
    data: {
      breadcrumb: {
        label: 'Accueil SFT',
        title: 'Liste des sites du module Suivi Flore Territoire.',
        iconClass: 'fa fa-home',
      },
    },
    children: [
      {
        path: '',
        component: ZpMapListComponent,
      },
      {
        path: ':idSite',
        data: {
          breadcrumb: {
            label: 'Site: :idSite',
            title: "Détail d'un site du module Suivi Flore Territoire.",
            iconClass: 'fa fa-map-marker',
          },
        },
        children: [
          {
            path: '',
            component: ListVisitComponent,
          },
          {
            path: 'visits/add',
            component: FormVisitComponent,
            data: {
              breadcrumb: {
                label: 'Ajout visite',
                title: "Ajout d'une visite du module Suivi Flore Territoire.",
                iconClass: 'fa fa-plus-circle',
              },
            },
          },
          {
            path: 'visits/:idVisit',
            data: {
              breadcrumb: {
                label: 'Visite : :idVisit',
                title: "Détail d'une visite du module Suivi Flore Territoire.",
                iconClass: 'fa fa-binoculars',
              },
            },
            children: [
              {
                path: '',
                component: DetailVisitComponent,
              },
              {
                path: 'edit',
                component: FormVisitComponent,
                data: {
                  breadcrumb: {
                    label: 'Édition',
                    title: "Édition d'une visite du module Suivi Flore Territoire.",
                    iconClass: 'fa fa-pencil-square-o',
                  },
                },
              },
            ],
          },
        ],
      },
    ],
  },
];

@NgModule({
  declarations: [
    BreadcrumbsComponent,
    ZpMapListComponent,
    ListVisitComponent,
    DetailVisitComponent,
    FormVisitComponent,
  ],
  imports: [
    GN2CommonModule,
    HttpClientXsrfModule.withOptions({
      cookieName: 'token',
      headerName: 'token',
    }),
    RouterModule.forChild(routes),
    CommonModule,
  ],
  providers: [HttpClient, DataService, StoreService],
  bootstrap: [],
})
export class GeonatureModule {}
