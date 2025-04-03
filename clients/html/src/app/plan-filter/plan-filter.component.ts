import { Component, OnInit, inject, input } from '@angular/core';
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
  defaultTieredContributionModel,
} from '../config/client_configuration';
import { PlanProviderService } from '../services/plan-provider.service';
import { Product } from '../data/products';
import { RosterEntry } from '../data/sponsor_roster';
import { PackageTypes } from '../config/package_types';
import { OrderByPipe } from './order-by.pipe';
import { PlanFilterPipe } from './plan-filter.pipe';
import { RouterLink } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { NgbCollapse, NgbTooltip } from '@ng-bootstrap/ng-bootstrap';
import { NgClass, NgStyle, TitleCasePipe, CurrencyPipe, DatePipe } from '@angular/common';

// Define interfaces for complex types
interface ProductInformation {
  metal_level?: string;
  provider_name: string;
  product_type: string;
  hsa_eligible: boolean;
  deductible: string;
  name: string;
  package_kinds?: PackageTypes[]; // Explicitly define package_kinds
  sic_code_factor?: number; // Explicitly define sic_code_factor
  group_size_factor?: (group_size: string) => number; // Explicitly define group_size_factor
  // Allow index signature for dynamic access in filterCarriers
  [key: string]: string | boolean | undefined | number | PackageTypes[] | ((arg: any) => any); // Add function type
}

// Represents a product after quoting/calculation
interface QuotedProduct {
  product_information: ProductInformation;
  total_cost: number;
  // Allow index signature if other properties are accessed dynamically in template
  [key: string]: any;
}

interface SicInfo {
  standardIndustryCodeCode: string;
}

interface EmployerDetails {
  employees: RosterEntry[];
  effectiveDate: string;
  sic: SicInfo;
  county: string;
  zip: string;
}

type FilterType = 'metalLevel' | 'productType' | 'insuranceCompany' | 'hsa';
type PlanType = 'health' | 'dental';

@Component({
  selector: 'app-plan-filter',
  standalone: true,
  templateUrl: './plan-filter.component.html',
  styleUrls: ['./plan-filter.component.css'],
  providers: [PlanProviderService],
  animations: [
    trigger('fadeInOut', [
      state(
        'void',
        style({
          opacity: 0,
        }),
      ),
      transition('void <=> *', animate(400)),
    ]),
  ],
  imports: [
    NgClass,
    NgbCollapse,
    NgbTooltip,
    FormsModule,
    NgStyle,
    RouterLink,
    TitleCasePipe,
    CurrencyPipe,
    DatePipe,
    PlanFilterPipe,
    OrderByPipe,
  ],
  host: { '(window:beforeunload)': 'unloadHandler($event)' },
})
export class PlanFilterComponent implements OnInit {
  private planService = inject(PlanProviderService);
  public tooltips = tooltips[0];
  public isCollapsed: boolean = false; // Assuming simple boolean state
  public metalLevelOptions: string[] = [];
  public carriers: string[] = [];
  public products: string[] = [];
  public hsaEligible: boolean[] = [];
  public filteredCarriers: QuotedProduct[] = [];
  public defaultCarriers: QuotedProduct[] = [];
  public employerDetails: EmployerDetails | null = null;
  public erEmployees: RosterEntry[] = [];
  public costShownText: string = '';
  public clearAll: boolean = false; // Initialize clearAll
  public filterLength: number = 0;
  public filterSelected = false;
  public tableHeaders = tableHeaders[0];
  selectedMetalLevels: { key: string; value: string }[] = [];
  selectedProductTypes: { key: string; value: string }[] = [];
  selectedInsuranceCompanies: { key: string; value: string }[] = [];
  selectedHSAs: { key: string; value: boolean }[] = [];
  filterCarriersResults: QuotedProduct[] = [];
  filterKeysSelected: FilterType[] = [];
  planPremiumsFrom: number | null = null;
  planPremiumsTo: number | null = null;
  yearlyMedicalDeductibleFrom: number | null = null;
  yearlyMedicalDeductibleTo: number | null = null;
  html2PDF = html2PDF;
  public pdfView = false;
  public btnName: string = '';
  public btnLink: string = '';
  public isLoading: boolean = false;
  public showPlansTable = false;
  selected = -1;

  private sponsorRoster: Array<RosterEntry> = [];
  public planFilter: PackageTypes | null = null; // Initialize planFilter
  public hasTierCompatibleType: boolean = false;
  public hasRelationshipCompatibleType: boolean = false;
  public kindFilteredProducts: Product[] = []; // Use Product type from import
  public sponsorProducts: Product[] = []; // Use Product type from import
  public filteredProducts: Product[] = []; // Use Product type from import
  public clientPreferences: ClientPreferences = CLIENT_PREFERENCES;
  public relationshipCalculator!: QuoteCalculator; // Use definite assignment assertion
  public tieredCalculator!: QuoteCalculator; // Use definite assignment assertion
  public relationshipContributionModel!: RelationshipContributionModel; // Use definite assignment assertion
  public tieredContributionModel!: TieredContributionModel; // Use definite assignment assertion
  sortDirection = true;
  sortKind: string = 'total_cost'; // Default sort kind
  iconSelected: string = 'col-6'; // Default selected icon column

  get sortFilter(): 'asc' | 'desc' {
    return this.sortDirection ? 'asc' : 'desc';
  }

  public planOptions = [
    { key: 'single_issuer', value: 'One Carrier', view: 'health' },
    { key: 'metal_level', value: 'One Level', view: 'health' },
    { key: 'single_product', value: 'One Plan', view: 'health' },
    { key: 'single_product', value: 'One Plan', view: 'dental' },
  ];

  carrierPlans = input<QuotedProduct[]>(); // Use QuotedProduct[]
  planType = input<PlanType>(); // Use PlanType ('health' | 'dental')

  unloadHandler(event: Event) {
    event.returnValue = false;
  }

  ngOnInit() {
    this.isLoading = false;
    const erDetails = localStorage.getItem('employerDetails');
    // Add type assertion for parsing JSON
    this.employerDetails = erDetails ? (JSON.parse(erDetails) as EmployerDetails) : null;
    this.filterLength = 0;

    const currentPlanType = this.planType(); // Store input value

    if (this.employerDetails && currentPlanType) {
      this.erEmployees = this.employerDetails.employees;

      if (this.erEmployees.length > 1) {
        this.costShownText = `${this.erEmployees.length} employees`;
      } else {
        this.costShownText = `${this.erEmployees.length} employee`;
      }

      this.isLoading = true;
      const startDate = this.employerDetails.effectiveDate; // Use property from interface
      this.planService.getPlansFor(
        this,
        this.employerDetails.sic.standardIndustryCodeCode, // Use property from interface
        new Date(startDate), // Convert string to Date object
        'MA',
        this.employerDetails.county, // Use property from interface
        this.employerDetails.zip, // Use property from interface
        currentPlanType, // Use stored value
        this,
      );
      this.sponsorRoster = this.employerDetails.employees.map(
        (employee): RosterEntry => ({
          ...employee, // Keep original properties like coverageKind
          dob: new Date(employee.dob), // Convert main dob
          dependents: employee.dependents.map((dep) => ({
            // Convert dependent dob
            ...dep,
            dob: new Date(dep.dob),
          })),
          // Removed will_enroll and roster_dependents from this mapped object structure
        }),
      );

      const formattedStartDate = new Date(startDate);

      this.tieredContributionModel = defaultTieredContributionModel();
      this.tieredCalculator = this.calculator(formattedStartDate, this.tieredContributionModel, currentPlanType, true);
      this.relationshipContributionModel = defaultRelationshipContributionModel();
      this.relationshipCalculator = this.calculator(
        formattedStartDate,
        this.relationshipContributionModel,
        currentPlanType,
      );
    }

    if (currentPlanType === 'health') {
      this.btnName = 'Select Dental';
      this.btnLink = '/employer-details/dental';
    } else {
      this.btnName = 'Back to Health';
      this.btnLink = '/employer-details/health';
    }
  }

  will_enroll(kind: string, currentPlanType: PlanType | undefined): boolean {
    // Add type for currentPlanType
    if (currentPlanType && (kind === '' || kind === 'both' || kind.includes(currentPlanType))) {
      return true;
    }
    return false;
  }

  loadData() {
    // Explicitly type the accumulator in reduce
    this.metalLevelOptions = this.filteredCarriers
      .map((plan) => plan.product_information.metal_level)
      .filter((level): level is string => level !== undefined) // Filter out undefined and type guard
      .reduce((unique: string[], item: string) => (unique.includes(item) ? unique : [...unique, item]), []);

    this.carriers = this.filteredCarriers
      .map((plan) => plan.product_information.provider_name)
      .reduce((unique: string[], item: string) => (unique.includes(item) ? unique : [...unique, item]), []);

    this.products = this.filteredCarriers
      .map((plan) => plan.product_information.product_type)
      .reduce((unique: string[], item: string) => (unique.includes(item) ? unique : [...unique, item]), []);

    this.hsaEligible = this.filteredCarriers
      .map((plan) => plan.product_information.hsa_eligible)
      .reduce((unique: boolean[], item: boolean) => (unique.includes(item) ? unique : [...unique, item]), []);

    this.filterLength = this.filteredCarriers.length;
    this.filterSelected = true;
  }

  // onProductsLoaded already correctly typed
  public onProductsLoaded(products: Array<Product>): void {
    this.planFilter = null;
    this.hasRelationshipCompatibleType = false;
    this.hasTierCompatibleType = false;
    this.sponsorProducts = products;
    this.kindFilteredProducts = products;
    this.filteredProducts = products;
    // Recalculate and load data if products are loaded after initial filter setup
    if (this.defaultCarriers.length > 0) {
      this.recalculate();
    }
  }

  changePackageFilter(newVal: PackageTypes | null) {
    // Type the parameter directly
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
      this.kindFilteredProducts = this.sponsorProducts.filter((p) => p.package_kinds.includes(packageKinds));
    }
    this.filteredProducts = this.kindFilteredProducts;
    this.recalculate();
    this.resetAll(); // Reset filters when package changes
    this.showPlansTable = true;
    this.sortDirection = true; // Reset sort direction
    this.sortKind = 'total_cost'; // Reset sort kind
    this.iconSelected = 'col-6'; // Reset sort icon
  }

  recalculate() {
    const currentPlanType = this.planType();
    if (!currentPlanType || this.kindFilteredProducts.length === 0) {
      // Don't recalculate if planType isn't set or no products to filter
      return;
    }
    const calculator = this.hasRelationshipCompatibleType ? this.relationshipCalculator : this.tieredCalculator;
    // Ensure calculator is initialized
    if (!calculator) {
      console.error('Calculator not initialized');
      return;
    }
    // Map the results to convert deductible from number to string
    const quotesFromCalculator = calculator.quoteProducts(this.kindFilteredProducts, this.planFilter);
    const newQuotes: QuotedProduct[] = quotesFromCalculator.map((quote) => ({
      ...quote,
      product_information: {
        ...quote.product_information,
        deductible: String(quote.product_information.deductible), // Convert number to string
      },
    }));
    const fProductsForCompare = this.filteredProducts.map((fp) => fp.name + fp.provider_name);
    const filteredQuotes = newQuotes.filter((nq) =>
      fProductsForCompare.includes(nq.product_information.name + nq.product_information.provider_name),
    );
    this.filteredCarriers = filteredQuotes;
    this.defaultCarriers = [...this.filteredCarriers]; // Create a copy for default state
    this.filterLength = filteredQuotes.length;
    this.filterSelected = true;
    this.loadData(); // Load filter options based on new data
  }

  isRelationshipPackageType(pt: PackageTypes): boolean {
    return this.clientPreferences.relationship_package_types.includes(pt);
  }

  isTieredPackageType(pt: PackageTypes): boolean {
    return this.clientPreferences.tiered_package_types.includes(pt);
  }

  private calculator(
    date: Date,
    contributionModel: TieredContributionModel | RelationshipContributionModel,
    currentPlanType: PlanType,
    isTieredCalculator?: boolean,
  ): QuoteCalculator {
    if (isTieredCalculator) {
      const calc = new this.clientPreferences.tiered_quote_calculator(
        date,
        contributionModel as TieredContributionModel, // Type assertion
        this.sponsorRoster,
        currentPlanType,
      );
      return calc;
    } else {
      const calculator = new this.clientPreferences.relationship_quote_calculator(
        date,
        contributionModel as RelationshipContributionModel, // Type assertion
        this.sponsorRoster,
        currentPlanType,
      );
      return calculator;
    }
  }

  selectedFilter(value: string | boolean, event: Event, type: FilterType) {
    // Use defined types
    const target = event.target as HTMLInputElement; // Type assertion for event target
    switch (type) {
      case 'metalLevel':
        if (target.checked) {
          // Ensure value is string for metal level
          if (typeof value === 'string') {
            this.selectedMetalLevels.push({ key: 'metal_level', value: value });
            this.filterKeysSelected.push(type);
          }
        } else {
          this.selectedMetalLevels = this.selectedMetalLevels.filter((ml) => ml.value != value);
          const keyIndex = this.filterKeysSelected.indexOf(type);
          if (keyIndex > -1) this.filterKeysSelected.splice(keyIndex, 1); // Remove only if found
        }
        break;
      case 'productType':
        if (target.checked) {
          if (typeof value === 'string') {
            this.selectedProductTypes.push({ key: 'product_type', value: value });
            this.filterKeysSelected.push(type);
          }
        } else {
          this.selectedProductTypes = this.selectedProductTypes.filter((ml) => ml.value != value);
          const keyIndex = this.filterKeysSelected.indexOf(type);
          if (keyIndex > -1) this.filterKeysSelected.splice(keyIndex, 1);
        }
        break;
      case 'insuranceCompany':
        if (target.checked) {
          if (typeof value === 'string') {
            this.selectedInsuranceCompanies.push({ key: 'provider_name', value: value });
            this.filterKeysSelected.push(type);
          }
        } else {
          this.selectedInsuranceCompanies = this.selectedInsuranceCompanies.filter((ml) => ml.value != value);
          const keyIndex = this.filterKeysSelected.indexOf(type);
          if (keyIndex > -1) this.filterKeysSelected.splice(keyIndex, 1);
        }
        break;
      case 'hsa':
        if (target.checked) {
          // Ensure value is boolean for HSA
          if (typeof value === 'boolean') {
            this.selectedHSAs.push({ key: 'hsa_eligible', value: value });
            this.filterKeysSelected.push(type);
          }
        } else {
          this.selectedHSAs = this.selectedHSAs.filter((ml) => ml.value != value);
          const keyIndex = this.filterKeysSelected.indexOf(type);
          if (keyIndex > -1) this.filterKeysSelected.splice(keyIndex, 1);
        }
        break;
    }
    this.filterCarriers();
  }

  // Helper function to flatten and deduplicate array of arrays
  private flattenAndDeduplicate<T>(arrayOfArrays: T[][]): T[] {
    const flattened = arrayOfArrays.flat();
    return Array.from(new Set(flattened.map((item) => JSON.stringify(item)))).map((str) => JSON.parse(str)) as T[];
  }

  filterCarriers() {
    const plans: QuotedProduct[] = this.defaultCarriers;
    let selected: QuotedProduct[] = [...plans]; // Start with all plans

    const filterGroups = [
      { selectedItems: this.selectedMetalLevels, key: 'metal_level' },
      { selectedItems: this.selectedProductTypes, key: 'product_type' },
      { selectedItems: this.selectedInsuranceCompanies, key: 'provider_name' },
      { selectedItems: this.selectedHSAs, key: 'hsa_eligible' },
    ];

    // Apply filters iteratively only if a selection exists for the group
    filterGroups.forEach((group) => {
      if (group.selectedItems.length > 0) {
        selected = selected.filter((plan) =>
          group.selectedItems.some((item) => plan.product_information[item.key] === item.value),
        );
      }
    });

    // Apply range filters
    if (this.yearlyMedicalDeductibleFrom !== null) {
      selected = selected.filter((plan) => {
        const deductible = parseInt(plan.product_information.deductible?.replace(/[$,]/g, '') || '0', 10);
        return !isNaN(deductible) && deductible >= (this.yearlyMedicalDeductibleFrom ?? -Infinity);
      });
    }

    if (this.yearlyMedicalDeductibleTo !== null) {
      selected = selected.filter((plan) => {
        const deductible = parseInt(plan.product_information.deductible?.replace(/[$,]/g, '') || '0', 10);
        return !isNaN(deductible) && deductible <= (this.yearlyMedicalDeductibleTo ?? Infinity);
      });
    }

    if (this.planPremiumsFrom !== null) {
      selected = selected.filter((plan) => plan.total_cost >= (this.planPremiumsFrom ?? -Infinity));
    }

    if (this.planPremiumsTo !== null) {
      selected = selected.filter((plan) => plan.total_cost <= (this.planPremiumsTo ?? Infinity));
    }

    this.filterCarriersResults = selected; // Store results before updating display
    this.filteredCarriers = selected;
    this.filterLength = this.filteredCarriers.length;
  }

  displayResults() {
    // This method seems redundant now as filterCarriers directly updates filteredCarriers
    // If specific logic is needed here, keep it, otherwise it can be removed.
    // For now, keeping the assignment as it was.
    this.filteredCarriers = this.filterCarriersResults;
    this.filterLength = this.filterCarriersResults.length;
  }

  resetAll() {
    this.filteredCarriers = [...this.defaultCarriers]; // Reset to a copy of default carriers
    this.filterLength = this.defaultCarriers.length;
    this.selectedMetalLevels = [];
    this.selectedProductTypes = [];
    this.selectedInsuranceCompanies = [];
    this.selectedHSAs = []; // Reset HSA selection
    this.filterCarriersResults = [];
    this.filterKeysSelected = [];
    this.yearlyMedicalDeductibleFrom = null; // Reset to null
    this.yearlyMedicalDeductibleTo = null; // Reset to null
    this.planPremiumsFrom = null; // Reset to null
    this.planPremiumsTo = null; // Reset to null

    // Reset checkboxes
    const checkboxes = document.querySelectorAll<HTMLInputElement>('.checkbox-input'); // Use querySelectorAll with type
    checkboxes.forEach((checkbox) => {
      checkbox.checked = false;
    });
  }

  getToolTip(type: string): string[] {
    // Type the parameter
    const currentPlanType = this.planType();
    if (!currentPlanType || !this.tooltips[currentPlanType]) return []; // Handle missing planType
    // Find the tooltip object for the given type
    const tooltipObj = this.tooltips[currentPlanType].find((item) => item[type]);
    return tooltipObj ? [tooltipObj[type]] : []; // Return array with the tooltip string or empty array
  }

  getTableHeader(col: string): string[] {
    // Type the parameter
    const currentPlanType = this.planType();
    if (!currentPlanType || !this.tableHeaders[currentPlanType]) return []; // Handle missing planType
    // Find the header object for the given column
    const headerObj = this.tableHeaders[currentPlanType].find((item) => item[col]);
    return headerObj ? [headerObj[col]] : []; // Return array with the header string or empty array
  }

  metalLevelCount(metalLevel: string): string | undefined {
    // Type the parameter, return string or undefined
    const currentPlanType = this.planType();
    if (currentPlanType === 'health') {
      const count = this.filteredCarriers.filter((plan) => plan.product_information.metal_level === metalLevel).length; // Get length directly
      return `(${count} Plans)`;
    }
    return undefined; // Return undefined if not health plan type
  }

  productTypeCounts(product: string): string {
    // Type the parameter
    const count = this.filteredCarriers.filter((plan) => plan.product_information.product_type === product).length; // Get length directly
    return `(${count} Plans)`;
  }

  hsaCounts(hsa: boolean): string {
    // Type the parameter
    const count = this.filteredCarriers.filter((plan) => plan.product_information.hsa_eligible === hsa).length; // Get length directly
    return `(${count} Plans)`;
  }

  showPDFGenerationMsg() {
    Swal.fire({
      title: 'Generating PDF',
      html: 'Please hold while PDF is generated.',
      icon: 'info',
      showConfirmButton: false,
      showCancelButton: false,
      backdrop: true,
      allowOutsideClick: false,
    });
  }

  downloadPdf() {
    this.pdfView = true;
    // Ensure table exists before trying to access it
    const table = document.getElementById('plan-table');
    if (!table) {
      console.error("Element with ID 'plan-table' not found.");
      Swal.fire('Error', 'Could not find table to generate PDF.', 'error');
      this.pdfView = false;
      return;
    }
    this.showPDFGenerationMsg();
    const currentPlanType = this.planType() || 'download'; // Default filename if planType is undefined
    this.html2PDF(table, {
      jsPDF: {
        unit: 'pt',
        format: 'a4',
      },
      imageType: 'image/png',
      output: `./pdf/${currentPlanType}.pdf`, // Use stored plan type
    })
      .then((pdf: any) => {
        // Add type for pdf if available from jspdf types
        pdf.save();
        Swal.close();
        // Ensure pdfView is reset even after success
        this.pdfView = false;
      })
      .catch((error: any) => {
        // Add error handling
        console.error('PDF generation failed:', error);
        Swal.fire('Error', 'PDF generation failed. Please try again.', 'error');
        this.pdfView = false;
      });
    // Consider removing the timeout or making it conditional on success/error
    // setTimeout(() => {
    //   this.pdfView = false;
    // }, 500);
  }

  getSbcDocument(key: string) {
    // Type the parameter
    const win = window.open('', '_blank');
    if (win) {
      // Check if window was opened successfully
      this.planService.getSbcDocumentFor(key, win);
    } else {
      console.error('Could not open new window for SBC document.');
      // Optionally show user message
      Swal.fire('Error', 'Could not open a new window. Please check your browser settings.', 'error');
    }
  }

  sortData(kind: string) {
    // Type the parameter
    if (this.sortKind === kind) {
      this.sortDirection = !this.sortDirection; // Toggle direction if same column
    } else {
      this.sortKind = kind;
      this.sortDirection = true; // Default to ascending for new column
    }
    this.setIcon(kind); // Update icon based on the new sort kind
  }

  setIcon(col: string) {
    // Type the parameter
    this.iconSelected = col;
  }

  showIcon(col: string): boolean {
    // Type the parameter, return boolean
    // Simplified logic: show icon if it's the currently selected column for sorting
    return this.iconSelected === col;
  }

  validateNumber(event: KeyboardEvent): boolean {
    // Type the parameter
    const charCode = event.which ? event.which : event.keyCode;
    // Allow backspace, delete, arrow keys, etc. (key codes < 32)
    // Allow numbers (48-57)
    if (charCode > 31 && (charCode < 48 || charCode > 57)) {
      event.preventDefault(); // Prevent the character from being entered
      return false;
    }
    return true;
  }
}
