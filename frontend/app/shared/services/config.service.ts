import { Injectable, Inject } from '@angular/core';

import { APP_CONFIG_TOKEN } from '@geonature_config/app.config';
import { ModuleConfig } from '../../module.config';

@Injectable()
export class ConfigService {

  constructor(@Inject(APP_CONFIG_TOKEN) private cfg) {}

  getModuleCode() {
    return ModuleConfig.MODULE_CODE;
  }

  getApplicationUrl() {
    return `${this.cfg.URL_APPLICATION}`;
  }

  getBackendUrl() {
    return `${this.cfg.API_ENDPOINT}`;
  }

  getBackendModuleUrl() {
    return `${this.cfg.API_ENDPOINT}${ModuleConfig.MODULE_URL}`;
  }

  getFrontendModuleUrl() {
    return ModuleConfig.MODULE_URL;
  }

  getExportUrl() {
    return `${this.getBackendModuleUrl()}/visits/export`;
  }

  get(param) {
    let value = param.split('.').reduce((a, b) => a[b], this.cfg);
    if (value === undefined) {
      value = param.split('.').reduce((a, b) => a[b], ModuleConfig);
    }
    return value;
  }
}
