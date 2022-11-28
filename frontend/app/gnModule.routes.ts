import { Routes } from '@angular/router';

import { VisitDetailComponent } from './visit-details/visit-details.component';
import { VisitFormComponent } from './visit-form/visit-form.component';
import { SiteDetailsComponent } from './site-details/site-details.component';
import { SitesMapListComponent } from './sites-map-list/sites-map-list.component';

// Module routing and breadcrumbs
export const routes: Routes = [
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
        component: SitesMapListComponent,
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
            component: SiteDetailsComponent,
          },
          {
            path: 'visits/add',
            component: VisitFormComponent,
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
                component: VisitDetailComponent,
              },
              {
                path: 'edit',
                component: VisitFormComponent,
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
