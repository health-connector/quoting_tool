import { Component, OnInit, Input, HostListener } from '@angular/core';
import { trigger, state, style, animate, transition } from '@angular/animations';
import tooltips from '../../data/tooltips.json';
import tableHeaders from '../../data/tableHeaders.json';
import html2PDF from 'jspdf-html2canvas';
import Swal from 'sweetalert2';

import { QuoteCalculator } from '../data/quotes';
import { TieredContributionModel, RelationshipContributionModel } from '../data/contribution_models';
import {
  ClientPreferences,
  CLIENT_PREFERENCES,
  defaultRelationshipContributionModel,
  defaultTieredContributionModel
} from '../config/client_configuration';
import { PlanProviderService } from '../services/plan-provider.service';
import { Product } from '../data/products';
import { RosterEntry } from '../data/sponsor_roster';
import { PackageTypes } from '../config/package_types';

@Component({
  selector: 'app-plan-filter',
  templateUrl: './plan-filter.component.html',
  styleUrls: ['./plan-filter.component.css'],
  providers: [PlanProviderService],
  animations: [
    trigger('fadeInOut', [
      state(
        'void',
        style({
          opacity: 0
        })
      ),
      transition('void <=> *', animate(400))
    ])
  ]
})
export class PlanFilterComponent implements OnInit {
  public tooltips = tooltips[0];
  public isCollapsed: any;
  public metalLevelOptions: any;
  public carriers: any;
  public products: any;
  public hsaEligible: any;
  public filteredCarriers: any;
  public defaultCarriers: any;
  public employerDetails: any;
  public effectiveDate: any;
  public erEmployees: any;
  public costShownText: any;
  public clearAll: boolean;
  public filterLength: number;
  public filterSelected = false;
  public tableHeaders = tableHeaders[0];
  selectedMetalLevels = [];
  selectedProductTypes = [];
  selectedInsuranceCompanies = [];
  selectedHSAs = [];
  filterCarriersResults = [];
  filterKeysSelected = [];
  planPremiumsFrom: any;
  planPremiumsTo: any;
  yearlyMedicalDeductibleFrom: any;
  yearlyMedicalDeductibleTo: any;
  html2PDF = html2PDF;
  public pdfView = false;
  public btnName: string;
  public btnLink: string;
  public isLoading: boolean;
  public showPlansTable = false;
  selected = -1;

  private sponsorRoster: Array<RosterEntry> = [];
  public planFilter: PackageTypes | null;
  public hasTierCompatibleType: boolean;
  public hasRelationshipCompatibleType: boolean;
  public kindFilteredProducts = [];
  public sponsorProducts = [];
  public filteredProducts = [];
  public clientPreferences: ClientPreferences = CLIENT_PREFERENCES;
  public relationshipCalculator: QuoteCalculator;
  public tieredCalculator: QuoteCalculator;
  public relationshipContributionModel: RelationshipContributionModel;
  public tieredContributionModel: TieredContributionModel;
  sortDirection = true;
  sortKind: any;
  iconSelected: any;
  filteredPlansByMetalLevel: any;
  filteredPlansByProductTypes: any;
  public availableProducts: any;
  get sortFilter() { return this.sortDirection ? 'asc' : 'desc'; }

  public planOptions = [
    { key: 'single_issuer', value: 'One Carrier', view: 'health' },
    { key: 'metal_level', value: 'One Level', view: 'health' },
    { key: 'single_product', value: 'One Plan', view: 'health' },
    { key: 'single_product', value: 'One Plan', view: 'dental' }
  ];

  @Input() carrierPlans: any;
  @Input() planType: any;

  @HostListener('window:beforeunload', ['$event']) unloadHandler(event: Event) {
    event.returnValue = false;
  }

  constructor(private planService: PlanProviderService) {}

  ngOnInit() {
    this.isLoading = false;
    const erDetails = localStorage.getItem('employerDetails');
    this.employerDetails = JSON.parse(erDetails);
    this.filterLength = 0;

    if (this.employerDetails) {
      this.erEmployees = this.employerDetails.employees;

      if (this.erEmployees.length > 1) {
        this.costShownText = `${this.erEmployees.length} employees`;
      } else {
        this.costShownText = `${this.erEmployees.length} employee`;
      }
    }

    if (this.employerDetails) {
      const consumer = this;
      this.isLoading = true;
      const startDate = this.employerDetails['effectiveDate'];
      this.planService.getPlansFor(
        this,
        this.employerDetails['sic']['standardIndustryCodeCode'],
        startDate,
        'MA',
        this.employerDetails['county'],
        this.employerDetails['zip'],
        this.planType,
        consumer
      );
      this.employerDetails.employees.forEach(function(employee) {
        const employeeJson = {
          dob: new Date(employee.dob),
          will_enroll: consumer.will_enroll(employee.coverageKind),
          roster_dependents: []
        };

        employee.dependents.forEach(function(dependent) {
          employeeJson.roster_dependents.push({
            dob: new Date(dependent.dob),
            relationship: dependent.relationship
          });
        });

        consumer.sponsorRoster.push(employeeJson);
      });

      const formattedStartDate = new Date(startDate);

      this.tieredContributionModel = defaultTieredContributionModel();
      this.tieredCalculator = this.calculator(formattedStartDate, this.tieredContributionModel, true);
      this.relationshipContributionModel = defaultRelationshipContributionModel();
      this.relationshipCalculator = this.calculator(formattedStartDate, this.relationshipContributionModel);
    }

    if (this.planType === 'health') {
      this.btnName = 'Select Dental';
      this.btnLink = '/employer-details/dental';
    } else {
      this.btnName = 'Back to Health';
      this.btnLink = '/employer-details/health';
    }
  }

  will_enroll(kind) {
    if (kind === '' || kind === 'both' || kind.match(this.planType)) {
      return true;
    }
    return false;
  }

  loadData() {
    this.metalLevelOptions = this.filteredCarriers
      .map((plan) => {
        if (plan['product_information']['metal_level']) {
          return plan['product_information']['metal_level'];
        }
      })
      .reduce((unique, item) => (unique.includes(item) ? unique : [...unique, item]), []);

    this.carriers = this.filteredCarriers
      .map((plan) => plan['product_information']['provider_name'])
      .reduce((unique, item) => (unique.includes(item) ? unique : [...unique, item]), []);

    this.products = this.filteredCarriers
      .map((plan) => plan['product_information']['product_type'])
      .reduce((unique, item) => (unique.includes(item) ? unique : [...unique, item]), []);

    this.hsaEligible = this.filteredCarriers
      .map((plan) => plan['product_information']['hsa_eligible'])
      .reduce((unique, item) => (unique.includes(item) ? unique : [...unique, item]), []);

    this.filterLength = this.filteredCarriers.length;
    this.filterSelected = true;
  }

  public onProductsLoaded(products: Array<Product>): void {
    this.planFilter = null;
    this.hasRelationshipCompatibleType = false;
    this.hasTierCompatibleType = false;
    this.sponsorProducts = products;
    this.kindFilteredProducts = products;
    this.filteredProducts = products;
  }

  changePackageFilter(evt) {
    const newVal: PackageTypes | null = <PackageTypes>evt;
    this.planFilter = newVal;
    this.hasTierCompatibleType = false;
    this.hasRelationshipCompatibleType = false;
    if (newVal != null) {
      this.hasRelationshipCompatibleType = this.isRelationshipPackageType(this.planFilter);
      this.hasTierCompatibleType = this.isTieredPackageType(this.planFilter);
    }
    const packageKinds = this.planFilter;
    this.kindFilteredProducts = this.sponsorProducts;
    if (packageKinds != null) {
      this.kindFilteredProducts = this.sponsorProducts.filter(function(p) {
        return p.package_kinds.includes(packageKinds);
      });
    }
    this.filteredProducts = this.kindFilteredProducts;
    this.recalculate();
    this.resetAll();
    this.showPlansTable = true;
    this.sortDirection = true;
  }

  recalculate() {
    const calculator = this.hasRelationshipCompatibleType ? this.relationshipCalculator : this.tieredCalculator;
    const newQuotes = calculator.quoteProducts(this.kindFilteredProducts, this.planFilter);
    const fProductsForCompare = this.filteredProducts.map(function(fp) {
      return fp.name + fp.provider_name;
    });
    const filteredQuotes = newQuotes.filter(function(nq) {
      return fProductsForCompare.includes(nq.product_information.name + nq.product_information.provider_name);
    });
    this.filteredCarriers = filteredQuotes;
    this.defaultCarriers = this.filteredCarriers;
    this.filterLength = filteredQuotes.length;
    this.filterSelected = true;
    this.loadData();
  }

  isRelationshipPackageType(pt: PackageTypes) {
    return this.clientPreferences.relationship_package_types.indexOf(pt) > -1;
  }

  isTieredPackageType(pt: PackageTypes) {
    return this.clientPreferences.tiered_package_types.indexOf(pt) > -1;
  }

  private calculator(date, contributionModel, isTiredCalculator?: boolean): QuoteCalculator {
    if (isTiredCalculator) {
      const calc = new this.clientPreferences.tiered_quote_calculator(date, contributionModel, this.sponsorRoster, this.planType);

      return calc;
    } else {
      const calculator = new this.clientPreferences.relationship_quote_calculator(
        date,
        contributionModel,
        this.sponsorRoster,
        this.planType
      );

      return calculator;
    }
  }

  selectedFilter(value, event, type) {
    switch (type) {
      case 'metalLevel':
        if (event.target.checked) {
          this.selectedMetalLevels.push({key: 'metal_level', value: value});
          this.filterKeysSelected.push(type);
        } else {
          const index = this.selectedMetalLevels.indexOf(value);
          const keyIndex = this.filterKeysSelected.indexOf(type);
          this.selectedMetalLevels.splice(index, 1);
          this.filterKeysSelected.splice(keyIndex, 1);
          this.filteredCarriers = this.defaultCarriers;
          this.filterLength = this.filteredCarriers.length;
        }
        break;
      case 'productType':
        if (event.target.checked) {
          this.selectedProductTypes.push({key: 'product_type', value: value});
          this.filterKeysSelected.push(type);
        } else {
          const index = this.selectedProductTypes.indexOf(value);
          const keyIndex = this.filterKeysSelected.indexOf(type);
          this.selectedProductTypes.splice(index, 1);
          this.filterKeysSelected.splice(keyIndex, 1);
          this.filteredCarriers = this.defaultCarriers;
          this.filterLength = this.filteredCarriers.length;
        }
        break;
      case 'insuranceCompany':
        if (event.target.checked) {
          this.selectedInsuranceCompanies.push({key: 'provider_name', value: value});
          this.filterKeysSelected.push(type);
        } else {
          const index = this.selectedInsuranceCompanies.indexOf(value);
          const keyIndex = this.filterKeysSelected.indexOf(type);
          this.selectedInsuranceCompanies.splice(index, 1);
          this.filterKeysSelected.splice(keyIndex, 1);
          this.filteredCarriers = this.defaultCarriers;
          this.filterLength = this.filteredCarriers.length;
        }
        break;
      case 'hsa':
        if (event.target.checked) {
          this.selectedHSAs.push({key: 'hsa_eligible', value: value});
          this.filterKeysSelected.push(type);
        } else {
          const index = this.selectedHSAs.indexOf(value);
          const keyIndex = this.filterKeysSelected.indexOf(type);
          this.selectedHSAs.splice(index, 1);
          this.filterKeysSelected.splice(keyIndex, 1);
          this.filteredCarriers = this.defaultCarriers;
          this.filterLength = this.filteredCarriers.length;
        }
        break;
    }
    this.filterCarriers();
  }

  combineArray(arr) {
    return [].concat.apply([], arr)
      .reduce((unique, item) => (unique.includes(item) ? unique : [...unique, item]), []);
  }

  filterCarriers() {
    const plans = this.filteredCarriers;
    const mlArray = [];
    const ptArray = [];
    const icArray = [];
    const hsaArray = [];
    let selected;

    if (this.selectedMetalLevels.length > 0) {
      this.selectedMetalLevels.map(ml => {
        mlArray.push(plans.filter(plan => plan['product_information'][ml.key] === ml.value));
        selected = this.combineArray(mlArray);
      });
    }

    if (this.selectedProductTypes.length > 0) {
      this.selectedProductTypes.map(pt => {
        ptArray.push(plans.filter(plan => plan['product_information'][pt.key] === pt.value));
        selected = this.combineArray(ptArray);
      });
    }

    if (this.selectedInsuranceCompanies.length > 0) {
      this.selectedInsuranceCompanies.map(ic => {
        icArray.push(plans.filter(plan => plan['product_information'][ic.key] === ic.value));
        selected = this.combineArray(icArray);
      });
    }

    if (this.selectedHSAs.length > 0) {
      this.selectedHSAs.map(hsa => {
        hsaArray.push(plans.filter(plan => plan['product_information'][hsa.key] === hsa.value));
        selected = this.combineArray(hsaArray);
      });
    }

    if (this.selectedInsuranceCompanies.length > 0 && this.selectedProductTypes.length > 0) {
      this.selectedProductTypes.map(pt => {
        selected = this.combineArray(icArray).filter(plan => plan['product_information'][pt.key] === pt.value);
      });
    }

    if (this.selectedInsuranceCompanies.length > 0 && this.selectedHSAs.length > 0) {
      this.selectedHSAs.map(hsa => {
        selected = this.combineArray(icArray).filter(plan => plan['product_information'][hsa.key] === hsa.value);
      });
    }

    if (this.selectedMetalLevels.length > 0 && this.selectedInsuranceCompanies.length > 0) {
      this.selectedInsuranceCompanies.map(ic => {
        selected = this.combineArray(mlArray).filter(plan => plan['product_information'][ic.key] === ic.value);
      });
    }

    if (this.selectedMetalLevels.length > 0 && this.selectedProductTypes.length > 0) {
      this.selectedProductTypes.map(pt => {
        selected = this.combineArray(mlArray).filter(plan => plan['product_information'][pt.key] === pt.value);
      });
    }

    if (this.selectedMetalLevels.length > 0 && this.selectedHSAs.length > 0) {
      this.selectedHSAs.map(hsa => {
        selected = this.combineArray(mlArray).filter(plan => plan['product_information'][hsa.key] === hsa.value);
      });
    }

    if (this.selectedMetalLevels.length > 0 && this.selectedProductTypes.length > 0 && this.selectedInsuranceCompanies.length > 0) {
      this.selectedInsuranceCompanies.map(ic => {
        selected = selected.filter(plan => plan['product_information'][ic.key] === ic.value);
      });
    }

    if (selected === undefined) {
      selected = plans;
    }

    if (this.yearlyMedicalDeductibleFrom && !this.yearlyMedicalDeductibleTo) {
      selected = selected.filter(plan => parseInt(plan['product_information']['deductible']
        .replace('$', '').replace(',', ''), 0) >= this.yearlyMedicalDeductibleFrom);
    }

    if (!this.yearlyMedicalDeductibleFrom && this.yearlyMedicalDeductibleTo) {
       selected = selected.filter(plan => parseInt(plan['product_information']['deductible']
        .replace('$', '').replace(',', ''), 0) <= this.yearlyMedicalDeductibleTo);
    }

    if (this.yearlyMedicalDeductibleFrom && this.yearlyMedicalDeductibleTo) {
       selected = selected.filter(plan => parseInt(plan['product_information']['deductible']
        .replace('$', '').replace(',', ''), 0) >= this.yearlyMedicalDeductibleFrom && parseInt(plan['product_information']['deductible']
        .replace('$', '').replace(',', ''), 0) <= this.yearlyMedicalDeductibleTo);
    }

    if (this.planPremiumsFrom && !this.planPremiumsTo) {
       selected = selected.filter(plan => plan['total_cost'] >= this.planPremiumsFrom);
    }

    if (!this.planPremiumsFrom && this.planPremiumsTo) {
       selected = selected.filter(plan => plan['total_cost'] <= this.planPremiumsTo);
    }

    if (this.planPremiumsFrom && this.planPremiumsTo) {
       selected = selected.filter(plan => plan['total_cost']
        >= this.planPremiumsFrom && plan['total_cost']
        <= this.planPremiumsTo);
    }

    this.filterCarriersResults = selected;
  }

  displayResults() {
    this.filteredCarriers = this.filterCarriersResults;
    this.filterLength = this.filterCarriersResults.length;
  }

  resetAll() {
    this.filteredCarriers = this.defaultCarriers;
    this.filterLength = this.defaultCarriers.length;
    this.selectedMetalLevels = [];
    this.selectedProductTypes = [];
    this.selectedInsuranceCompanies = [];
    this.filterCarriersResults = [];
    this.filterKeysSelected = [];
    this.yearlyMedicalDeductibleFrom = '';
    this.yearlyMedicalDeductibleTo = '';
    this.planPremiumsFrom = '';
    this.planPremiumsTo = '';

    const checkboxes = document.getElementsByClassName('checkbox-input');
    for (let i = 0; i < checkboxes.length; i++) {
      // @ts-ignore
      checkboxes[i].checked = false;
    }
  }

  getToolTip(type) {
    return this.tooltips[this.planType].map((key) => key[type]);
  }

  getTableHeader(col) {
    return this.tableHeaders[this.planType].map((key) => key[col]);
  }

  metalLevelCount(metalLevel, planType) {
    if (planType === 'health') {
      const count = this.filteredCarriers.filter((plan) => plan['product_information']['metal_level'] === metalLevel);
      return `(${count.length} Plans)`;
    }
  }

  productTypeCounts(product) {
    const count = this.filteredCarriers.filter((plan) => plan['product_information']['product_type'] === product);
    return `(${count.length} Plans)`;
  }

  hsaCounts(hsa) {
    const count = this.filteredCarriers.filter((plan) => plan['product_information']['hsa_eligible'] === hsa);
    return `(${count.length} Plans)`;
  }

  showPDFGenerationMsg() {
    Swal.fire({
      title: 'Generating PDF',
      html: 'Please hold while PDF is generated.',
      icon: 'info',
      showConfirmButton: false,
      showCancelButton: false,
      backdrop: true,
      allowOutsideClick: false
    });
  }

  downloadPdf() {
    this.pdfView = true;
    const table = document.getElementById('plan-table');
    this.showPDFGenerationMsg();
    this.html2PDF(table, {
      jsPDF: {
        unit: 'pt',
        format: 'a4'
      },
      imageType: 'image/png',
      output: `./pdf/${this.planType}.pdf`,
      success: function(pdf) {
        pdf.save();
        Swal.close();
      }
    });
    setTimeout(() => {
      this.pdfView = false;
    }, 500);
  }

  getSbcDocument(key) {
    const win = window.open('', '_blank');
    this.planService.getSbcDocumentFor(key, win);
  }

  sortData(kind) {
    this.sortKind = kind;
    this.sortDirection = !this.sortDirection;
  }

  setIcon(col) {
    this.iconSelected = col;
  }

  showIcon(col) {
    if (this.iconSelected === undefined && col === 'col-6') {
      return true;
    } else if (this.iconSelected === col) {
      return true;
    }
  }

  validateNumber(event) {
    const charCode = (event.which) ? event.which : event.keyCode;
    if (charCode > 31 && (charCode < 48 || charCode > 57)) {
      return false;
    }
    return true;
  }
}
