import { Injectable, Inject } from '@angular/core';

import { ConfigService as GnConfigService } from '@geonature/services/config.service';


@Injectable()
export class ConfigService {

  constructor(public cfg: GnConfigService) {}


  getApplicationUrl() {
    return `${this.cfg.URL_APPLICATION}`;
  }

  getBackendUrl() {
    return `${this.cfg.API_ENDPOINT}`;
  }

  getBackendModuleUrl() {
    return `${this.cfg.API_ENDPOINT}/sft`;
  }

  getFrontendModuleUrl() {
    return "/sft";
  }

  getExportUrl() {
    return `${this.getBackendModuleUrl()}/visits/export`;
  }

  get(param) {
    let value = param.split('.').reduce((a, b) => a[b], this.cfg);
    if (value === undefined) {
      value = param.split('.').reduce((a, b) => a[b], this.cfg["SFT"]);
    }
    return value;
  }
}
