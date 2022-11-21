import { filter, distinctUntilChanged } from 'rxjs/operators';

import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router, NavigationEnd, Event } from '@angular/router';

import { IBreadCrumb } from './breadcrumb.interface';

/**
 * Classe building breadcrumbs with routes configurations (see gnModule.module.ts file).
 *
 * Source: https://medium.com/@bo.vandersteene/angular-5-breadcrumb-c225fd9df5cf
 * See also: https://vsavkin.tumblr.com/post/146722301646/angular-router-empty-paths-componentless-routes
 */
@Component({
  selector: 'sft-breadcrumbs',
  templateUrl: './breadcrumbs.component.html',
})
export class BreadcrumbsComponent implements OnInit {
  public breadcrumbs: IBreadCrumb[];

  constructor(private router: Router, private activatedRoute: ActivatedRoute) {
    this.breadcrumbs = this.buildBreadCrumb(this.activatedRoute.root);
  }

  ngOnInit() {
    this.router.events
      .pipe(
        filter((event: Event) => event instanceof NavigationEnd),
        distinctUntilChanged()
      )
      .subscribe(() => {
        this.breadcrumbs = this.buildBreadCrumb(this.activatedRoute.root);
      });
  }

  /**
   * Recursively build breadcrumb according to activated route.
   * @param route
   * @param url
   * @param breadcrumbs
   */
  buildBreadCrumb(
    route: ActivatedRoute,
    url: string = '',
    breadcrumbs: IBreadCrumb[] = []
  ): IBreadCrumb[] {
    // If no routeConfig is avalailable we are on the root path
    let data =
      route.routeConfig && route.routeConfig.data && route.routeConfig.data.breadcrumb
        ? route.routeConfig.data.breadcrumb
        : { label: '', iconClass: '', title: '' };
    let label = data.label;
    let iconClass = data.iconClass || '';
    let title = data.title || '';
    let path = route.routeConfig && route.routeConfig.path ? route.routeConfig.path : '';

    // If the route is dynamic route such as ':id', remove it
    const lastRoutePart = path.split('/').pop();
    const isDynamicRoute = lastRoutePart.startsWith(':');
    if (isDynamicRoute) {
      const paramName = lastRoutePart.split(':')[1];
      const paramValue = route.snapshot.params[paramName];
      path = path.replace(lastRoutePart, paramValue);
      label = label.replace(`:${paramName}`, paramValue);
    }

    // In the routeConfig the complete path is not available,
    // so we rebuild it each time
    const nextUrl = path ? `${url}/${path}` : url;

    const breadcrumb: IBreadCrumb = {
      label: label,
      iconClass: iconClass,
      title: title,
      url: nextUrl,
    };

    // Only adding route with non-empty label
    const newBreadcrumbs = breadcrumb.label ? [...breadcrumbs, breadcrumb] : [...breadcrumbs];
    if (route.firstChild) {
      // If we are not on our current path yet,
      // there will be more children to look after, to build our breadcumb
      return this.buildBreadCrumb(route.firstChild, nextUrl, newBreadcrumbs);
    }
    return newBreadcrumbs;
  }
}
