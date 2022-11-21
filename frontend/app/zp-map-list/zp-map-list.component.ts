import {
  Component,
  OnInit,
  AfterViewInit,
  Input,
  Output,
  EventEmitter,
  HostListener,
  ViewChild,
} from '@angular/core';
import { Router } from '@angular/router';
import { FormGroup, FormBuilder, FormControl } from '@angular/forms';

import { DatatableComponent } from '@swimlane/ngx-datatable/release';

import { MapService } from '@geonature_common/map/map.service';
import { MapListService } from '@geonature_common/map-list/map-list.service';

import { DataService } from '../services/data.service';
import { StoreService } from '../services/store.service';
import { ModuleConfig } from '../module.config';

@Component({
  selector: 'pnx-zp-map-list',
  templateUrl: './zp-map-list.component.html',
  styleUrls: ['./zp-map-list.component.scss'],
})
export class ZpMapListComponent implements OnInit, AfterViewInit {
  @Input()
  searchTaxon: string;
  @Output()
  onDeleteFilter = new EventEmitter<any>();
  @ViewChild('dataTable')
  dataTable: DatatableComponent;
  public zps;
  private dataTableLatestWidth: number;
  public loadingIndicator = false;
  // Height in pixel of a datatable row
  public rowHeight: number = 50;
  // Minimal number of rows in datable
  public defaultRowNumber: number = 5;
  public rowNumber: number;
  public filteredData = [];
  public filterForm: FormGroup;
  public yearsList = [];
  public organismsList = [];
  public municipalitiesList = [];

  constructor(
    public mapService: MapService,
    private api: DataService,
    public router: Router,
    public storeService: StoreService,
    public mapListService: MapListService,
    private formBuilder: FormBuilder,
  ) {}

  ngOnInit() {
    this.loadInitialData();
    this.initializeRowNumber();
    this.initializeFilterForm();
    this.initializeFilterControls();
    this.initializeMapList();
  }

  private initializeRowNumber() {
    // Get wiewport height to set the number of rows in datatable
    const screenHeight = document.documentElement.clientHeight;
    this.rowNumber = this.calculateRowNumber(screenHeight);
  }

  private loadInitialData() {
    this.storeService.loadQueryString();
    this.onChargeList();
  }

  private initializeFilterForm() {
    this.filterForm = this.formBuilder.group({
      taxonFilter: JSON.parse(localStorage.getItem('sft-filters-taxon')),
      yearFilter: this.getInitialFilterValue('year'),
      organismFilter: this.getInitialFilterValue('organism'),
      municipalityFilter: this.getInitialFilterValue('municipality'),
    });
  }

  private getInitialFilterValue(filterName) {
    let value = null;
    if (this.storeService.queryString.has(filterName)) {
      value = this.storeService.queryString.get(filterName);
    }
    return value;
  }

  private initializeFilterControls() {
    // Year
    this.filterForm.controls.yearFilter.valueChanges
      .filter(select => !select || select !== null)
      .subscribe(item => {
        this.onSearchYear(item);
      });

    this.filterForm.controls.yearFilter.valueChanges
      .filter(input => !input || input === null)
      .subscribe(item => {
        this.deleteQueryString('year');
        this.onDeleteFilter.emit(item);
      });

    // Organism
    this.filterForm.controls.organismFilter.valueChanges
      .filter(select => !select || select !== null)
      .subscribe(item => {
        this.onSearchOrganism(item);
      });

    this.filterForm.controls.organismFilter.valueChanges
      .filter(input => !input || input === null)
      .subscribe(item => {
        this.deleteQueryString('organism');
        this.onDeleteFilter.emit(item);
      });

    // Municipality
    this.filterForm.controls.municipalityFilter.valueChanges
      .filter(select => !select || select !== null)
      .subscribe(item => {
        this.onSearchMunicipality(item);
      });

    this.filterForm.controls.municipalityFilter.valueChanges
      .filter(input => !input || input === null)
      .subscribe(item => {
        this.deleteQueryString('municipality');
        this.onDeleteFilter.emit(item);
      });
  }

  private initializeMapList() {
    this.mapListService.idName = 'id_infos_site';

    // Observable on mapListService.currentIndexRow to find the current page
    this.mapListService.currentIndexRow$.subscribe(indexRow => {
      const currentPage = Math.trunc(indexRow / this.rowNumber);
      this.dataTable.offset = currentPage;
    });

    this.storeService.initialize();
  }

  ngAfterViewInit() {
    this.mapListService.enableMapListConnexion(this.mapService.getMap());

    this.loadYears();
    this.loadOrganisms();
    this.loadMunicipalities();

    // WARNING: use Promise to avoid ExpressionChangedAfterItHasBeenCheckedError
    // See: https://angular.io/errors/NG0100
    Promise.resolve(null).then(() => this.recalculateDataTableSize());
  }

  private loadYears() {
    this.api.getVisitsYears().subscribe(data => {
      this.yearsList = data;
      this.yearsList.sort().reverse();
    });
  }

  private loadMunicipalities() {
    this.api.getMunicipalities().subscribe(data => {
      this.municipalitiesList = data;
      this.municipalitiesList.sort((a, b) => {
        return a.name.localeCompare(b.name);
      });
    });
  }

  private loadOrganisms() {
    this.api.getOrganisms().subscribe(data => {
      this.organismsList = data;
      this.organismsList.sort();
      this.organismsList.sort((a, b) => {
        return a.name.localeCompare(b.name);
      });
    });
  }

  private recalculateDataTableSize() {
    if (this.dataTable && this.dataTable.element.clientWidth !== this.dataTableLatestWidth) {
      this.dataTableLatestWidth = this.dataTable.element.clientWidth;
      this.dataTable.recalculate();
      this.dataTable.recalculateColumns();
      window.dispatchEvent(new Event('resize'));
    }
  }

  @HostListener('window:resize', ['$event'])
  onResize(event) {
    this.updateDataTableRowNumber(event.target.innerHeight);
  }

  /** Update the number of row per page when resize the window */
  private updateDataTableRowNumber(height: number) {
    this.rowNumber = this.calculateRowNumber(height);
  }

  /** Calculate the number of row with the client screen height */
  private calculateRowNumber(screenHeight: number): number {
    const dataTableTop = this.dataTable.element.getBoundingClientRect().top;
    const footerHeight = document.querySelector('#end-btn').getBoundingClientRect().height;
    const outerheight =
      dataTableTop + this.dataTable.headerHeight + this.dataTable.footerHeight + footerHeight;

    let rowNumber = Math.trunc((screenHeight - outerheight) / this.rowHeight);
    rowNumber = rowNumber < this.defaultRowNumber ? this.defaultRowNumber : rowNumber;
    return rowNumber;
  }

  onEachFeature(feature, layer) {
    this.mapListService.layerDict[feature.id] = layer;

    layer.on({
      click: e => {
        this.mapListService.toggleStyle(layer);
        this.mapListService.mapSelected.next(feature.id);
      },
    });
  }

  onInfo(id_base_site) {
    this.router.navigate([`${ModuleConfig.MODULE_URL}/sites`, id_base_site]);
  }

  onTaxonChanged(event) {
    this.setQueryString('cd_nom', event.item.cd_nom);
    localStorage.setItem('sft-filters-taxon', JSON.stringify(event.item));
  }

  onTaxonDeleted(event) {
    this.deleteQueryString('cd_nom');
    this.onDeleteFilter.emit(event);
    localStorage.removeItem('sft-filters-taxon');
  }

  private onSearchYear(event) {
    this.setQueryString('year', event);
  }

  private onSearchOrganism(event) {
    this.setQueryString('organism', event);
  }

  private onSearchMunicipality(event) {
    this.setQueryString('municipality', event);
  }

  private setQueryString(param: string, value) {
    this.storeService.queryString = this.storeService.queryString.set(param, value);
    this.storeService.saveQueryString();
    this.onChargeList();
  }

  private deleteQueryString(param: string) {
    this.storeService.queryString = this.storeService.queryString.delete(param);
    this.storeService.saveQueryString();
    this.onChargeList();
  }

  private onChargeList() {
    this.loadingIndicator = true;
    this.api.getZp(this.storeService.queryString).subscribe(data => {
      this.zps = data;
      this.mapListService.loadTableData(data);
      this.filteredData = this.mapListService.tableData;
      this.loadingIndicator = false;
    });
  }
}
