import { Component, OnInit, inject, input, OnDestroy } from '@angular/core';
import { trigger, state, style, animate, transition } from '@angular/animations';
import { NgClass, NgStyle, TitleCasePipe, CurrencyPipe, DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { NgbCollapse, NgbTooltip } from '@ng-bootstrap/ng-bootstrap';
import Swal from 'sweetalert2';
import html2PDF from 'jspdf-html2canvas';
import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators'; // Import takeUntil if using PlanProviderService observables

import tooltipsData from '../../../data/tooltips.json';
import tableHeadersData from '../../../data/tableHeaders.json';

import {
  ClientPreferences,
  CLIENT_PREFERENCES,
  defaultRelationshipContributionModel,
  defaultTieredContributionModel,
} from '../../config/client_configuration';
import { PackageTypes } from '../../config/package_types';
import { RelationshipContributionModel, TieredContributionModel } from '../../data/contribution_models';
import { Product } from '../../data/products';
import { QuoteCalculator } from '../../data/quotes';
import { RosterEntry } from '../../data/sponsor_roster';
import { OrderByPipe } from '../../pipes/order-by.pipe';
import { PlanFilterPipe } from '../../pipes/plan-filter.pipe';
import { PlanProviderService } from '../../services/plan-provider.service';
// Import ContributionRelationship enum
import { ContributionRelationship } from '../../config/contribution_relationship';

// --- Interfaces ---
interface ProductInformation {
  metal_level?: string;
  provider_name: string;
  product_type: string;
  hsa_eligible: boolean;
  deductible: string;
  name: string;
  package_kinds?: PackageTypes[];
  sic_code_factor?: number;
  group_size_factor?: (group_size: string) => number;
  [key: string]: string | boolean | undefined | number | PackageTypes[] | ((arg: unknown) => unknown);
}

interface QuotedProduct {
  product_information: ProductInformation;
  total_cost: number;
  deductible: string; // For display and sorting
  sponsor_cost: number; // For sorting
  [key: string]: unknown; // Allow dynamic access
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

// --- Types ---
type FilterType = 'metalLevel' | 'productType' | 'insuranceCompany' | 'hsa';
type PlanType = 'health' | 'dental';
type SortKey = keyof QuotedProduct | 'metal_level' | 'product_type' | 'provider_name' | 'hsa_eligible'; // Extend as needed

// --- Constants ---
const FILTER_KEYS = {
  METAL_LEVEL: 'metal_level',
  PRODUCT_TYPE: 'product_type',
  PROVIDER_NAME: 'provider_name',
  HSA_ELIGIBLE: 'hsa_eligible',
} as const;

const DEFAULT_SORT_KIND: SortKey = 'total_cost';
const DEFAULT_ICON_COL = 'col-6'; // TODO: Revisit if this is the best way to track icon column

@Component({
  selector: 'app-plan-filter',
  standalone: true,
  templateUrl: './plan-filter.component.html',
  styleUrls: ['./plan-filter.component.css'],
  providers: [PlanProviderService],
  animations: [trigger('fadeInOut', [state('void', style({ opacity: 0 })), transition('void <=> *', animate(400))])],
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
export class PlanFilterComponent implements OnInit, OnDestroy {
  // --- Inputs ---
  carrierPlans = input<QuotedProduct[]>(); // TODO: Is this input still needed if component fetches data?
  planType = input.required<PlanType>(); // Use required input

  // --- Injected Services ---
  private planService = inject(PlanProviderService);
  private clientPreferences: ClientPreferences = CLIENT_PREFERENCES;

  // --- Configuration Data ---
  public tooltips = tooltipsData[0]; // Consider making type-safe access
  public tableHeaders = tableHeadersData[0]; // Consider making type-safe access

  // --- Component State ---
  public isLoading = false;
  public showPlansTable = false;
  public isCollapsed = false;
  public pdfView = false;
  public filterLength = 0;
  public costShownText = '';
  public btnName = '';
  public btnLink = '';
  public filterSelected = false; // Add filterSelected back

  // --- Data Properties ---
  public employerDetails: EmployerDetails | null = null; // Must be public for template access
  private sponsorRoster: RosterEntry[] = [];
  private sponsorProducts: Product[] = []; // All products fetched for the sponsor
  private kindFilteredProducts: Product[] = []; // Products filtered by current PackageType
  public defaultCarriers: QuotedProduct[] = []; // All quoted products before filtering
  public filteredCarriers: QuotedProduct[] = []; // Displayed products after filtering

  // --- Calculators ---
  private relationshipCalculator!: QuoteCalculator;
  private tieredCalculator!: QuoteCalculator;
  private relationshipContributionModel!: RelationshipContributionModel;
  private tieredContributionModel!: TieredContributionModel;

  // --- Filtering State ---
  public planFilter: PackageTypes | null = null; // Selected package type filter
  public selectedMetalLevels: { key: string; value: string }[] = [];
  public selectedProductTypes: { key: string; value: string }[] = [];
  public selectedInsuranceCompanies: { key: string; value: string }[] = [];
  public selectedHSAs: { key: string; value: boolean }[] = [];
  public planPremiumsFrom: number | null = null;
  public planPremiumsTo: number | null = null;
  public yearlyMedicalDeductibleFrom: number | null = null;
  public yearlyMedicalDeductibleTo: number | null = null;

  // --- Filter Options (Derived) ---
  public metalLevelOptions: string[] = [];
  public carriers: string[] = [];
  public products: string[] = [];
  public hsaEligible: boolean[] = [];

  // --- Sorting State ---
  public sortDirection = true; // true = asc, false = desc
  public sortKind: SortKey = DEFAULT_SORT_KIND;
  public iconSelected: string = DEFAULT_ICON_COL; // Tracks which column header shows the sort icon

  // --- Package Type Compatibility ---
  public hasTierCompatibleType = false;
  public hasRelationshipCompatibleType = false;

  // --- Misc ---
  private destroy$ = new Subject<void>();
  public html2PDF = html2PDF; // Expose for template

  // --- Lifecycle Hooks ---
  ngOnInit() {
    this.isLoading = true;
    this._loadEmployerDetails();

    const currentPlanType = this.planType();
    if (!this.employerDetails || !currentPlanType) {
      console.warn('[PlanFilterComponent] Missing employer details or plan type on init.');
      this.isLoading = false;
      // Handle error state appropriately, maybe show a message
      return;
    }

    this._updateButtonLinks(currentPlanType);
    this._initializeCalculatorsAndRoster(new Date(this.employerDetails.effectiveDate), currentPlanType);
    this._fetchInitialPlans(currentPlanType);
  }

  ngOnDestroy() {
    this.destroy$.next();
    this.destroy$.complete();
  }

  unloadHandler(event: Event) {
    // Consider if this is still necessary or if alternative UX (like auto-save) is better
    event.returnValue = false;
  }

  // --- Initialization Helpers ---
  private _loadEmployerDetails(): void {
    const erDetails = localStorage.getItem('employerDetails');
    try {
      this.employerDetails = erDetails ? (JSON.parse(erDetails) as EmployerDetails) : null;
      this.filterLength = 0; // Reset count initially
      if (this.employerDetails) {
        this.costShownText =
          this.employerDetails.employees.length > 1
            ? `${this.employerDetails.employees.length} employees`
            : `${this.employerDetails.employees.length} employee`;
      } else {
        this.costShownText = '0 employees';
      }
    } catch (error) {
      console.error('Failed to parse employer details from localStorage', error);
      this.employerDetails = null;
      // Handle error: maybe redirect or show error message
    }
  }

  private _initializeCalculatorsAndRoster(effectiveDate: Date, planType: PlanType): void {
    if (!this.employerDetails) return;

    // Convert employee data to proper RosterEntry format
    this.sponsorRoster = this.employerDetails.employees.map((employee): RosterEntry => {
      // Convert dependents to proper format with ContributionRelationship enum
      const processedDependents = employee.dependents.map((dep) => {
        // Convert string relationship to ContributionRelationship enum
        let relationship;
        switch (dep.relationship.trim()) {
          case 'Self':
            relationship = ContributionRelationship.SELF;
            break;
          case 'Spouse':
            relationship = ContributionRelationship.SPOUSE;
            break;
          case 'Child':
            relationship = ContributionRelationship.CHILD;
            break;
          case 'Domestic Partner':
            relationship = ContributionRelationship.DOMESTIC_PARTNER;
            break;
          default:
            console.warn(`Unknown relationship type: ${dep.relationship}, defaulting to SELF`);
            relationship = ContributionRelationship.SELF;
        }

        return {
          dob: new Date(dep.dob),
          relationship: relationship,
        };
      });

      // Create a complete roster entry with all required fields
      return {
        ...employee,
        dob: new Date(employee.dob),
        dependents: employee.dependents.map((dep) => ({
          ...dep,
          dob: new Date(dep.dob),
        })),
        // Add roster_dependents property needed by the calculator
        roster_dependents: processedDependents,
        will_enroll: true, // Ensure this is set
        coverageKind: planType, // Set the coverage kind
      };
    });

    // Debug log only first employee to avoid cluttering the console
    console.log('[DEBUG] First roster entry:', this.sponsorRoster[0]);

    this.tieredContributionModel = defaultTieredContributionModel();
    this.tieredCalculator = this._createCalculator(effectiveDate, this.tieredContributionModel, planType, true);
    this.relationshipContributionModel = defaultRelationshipContributionModel();
    this.relationshipCalculator = this._createCalculator(
      effectiveDate,
      this.relationshipContributionModel,
      planType,
      false,
    );
  }

  private _fetchInitialPlans(planType: PlanType): void {
    if (!this.employerDetails) return;

    this.planService.getPlansFor(
      this, // TODO: Revisit if 'this' is the correct callback context for PlanProviderService
      this.employerDetails.sic.standardIndustryCodeCode,
      new Date(this.employerDetails.effectiveDate),
      'MA', // TODO: Make region dynamic?
      this.employerDetails.county,
      this.employerDetails.zip,
      planType,
      this, // TODO: Callback context again
    );
    // If getPlansFor returns an Observable:
    // .pipe(takeUntil(this.destroy$))
    // .subscribe({
    //   next: (products) => this.onProductsLoaded(products), // Assuming service calls onProductsLoaded or returns data
    //   error: (err) => {
    //     console.error("Failed to fetch plans", err);
    //     this.isLoading = false;
    //     // Show error message
    //   },
    //   complete: () => this.isLoading = false // Might be set in onProductsLoaded instead
    // });
    // If getPlansFor uses the callback pattern (like original code), keep as is,
    // but ensure isLoading is handled correctly in onProductsLoaded and error scenarios.
  }

  private _updateButtonLinks(planType: PlanType): void {
    if (planType === 'health') {
      this.btnName = 'Select Dental';
      this.btnLink = '/employer-details/dental';
    } else {
      this.btnName = 'Back to Health';
      this.btnLink = '/employer-details/health';
    }
  }

  // --- Product Loading and Recalculation ---

  // Called by PlanProviderService (or subscription) when products are fetched
  public onProductsLoaded(products: Product[]): void {
    console.log('[PlanFilterComponent] onProductsLoaded received products:', products.length);
    this.isLoading = true; // Start processing
    this.sponsorProducts = products;
    this.kindFilteredProducts = [...products]; // Initially, all fetched products are kind-filtered

    // Apply initial package filter if one exists, otherwise use all products
    this._applyPackageFilter();
    this._recalculateQuotes();

    this.showPlansTable = true;
    this.isLoading = false; // Finish processing
  }

  private _recalculateQuotes(): void {
    const currentPlanType = this.planType();
    console.log(
      '[PlanFilterComponent] recalculate started. kindFilteredProducts:',
      this.kindFilteredProducts.length,
      'planFilter:',
      this.planFilter,
    );

    if (!currentPlanType || this.kindFilteredProducts.length === 0) {
      console.log('[PlanFilterComponent] recalculate skipped (no plan type or products).');
      this.defaultCarriers = [];
      this.filteredCarriers = [];
      this._updateFilterOptionsAndCounts();
      return;
    }

    const calculator = this.hasRelationshipCompatibleType ? this.relationshipCalculator : this.tieredCalculator;

    if (!calculator) {
      console.error('[PlanFilterComponent] recalculate failed: Calculator not initialized');
      this.defaultCarriers = [];
      this.filteredCarriers = [];
      this._updateFilterOptionsAndCounts();
      return;
    }

    console.log(
      '[PlanFilterComponent] recalculate using calculator:',
      this.hasRelationshipCompatibleType ? 'relationship' : 'tiered',
    );

    const quotesFromCalculator = calculator.quoteProducts(this.kindFilteredProducts, this.planFilter);

    // Debug check for the first calculated quote
    if (quotesFromCalculator.length > 0) {
      console.log('[DEBUG] First quote total_cost:', quotesFromCalculator[0].total_cost);
    }

    const newQuotes: QuotedProduct[] = quotesFromCalculator.map(
      (quote): QuotedProduct => ({
        ...quote,
        product_information: {
          ...quote.product_information,
          deductible: String(quote.product_information.deductible ?? ''), // Ensure string
        },
        deductible: String(quote.product_information.deductible ?? ''), // Top-level for sorting/display
        sponsor_cost: quote.total_cost, // Using total_cost as sponsor_cost (since contribution is 100%)
      }),
    );

    // Debug check for the first mapped quote
    if (newQuotes.length > 0) {
      console.log('[DEBUG] First mapped quote sponsor_cost:', newQuotes[0].sponsor_cost);
    }

    this.defaultCarriers = newQuotes;
    console.log('[PlanFilterComponent] recalculate finished. defaultCarriers:', this.defaultCarriers.length);

    // Apply existing filters to the newly calculated default carriers
    this.applyFiltersAndUpdateDisplay();
  }

  private _createCalculator(
    date: Date,
    contributionModel: TieredContributionModel | RelationshipContributionModel,
    planType: PlanType,
    isTieredCalculator: boolean,
  ): QuoteCalculator {
    const calculatorClass = isTieredCalculator
      ? this.clientPreferences.tiered_quote_calculator
      : this.clientPreferences.relationship_quote_calculator;

    // Type assertion is okay here if we trust clientPreferences structure
    return new calculatorClass(
      date,
      contributionModel as any, // Use 'any' or ensure constructor signatures match
      this.sponsorRoster,
      planType,
    );
  }

  // --- Package Filtering ---

  public changePackageFilter(newVal: string | null): void {
    this.planFilter = newVal as PackageTypes; // Assuming string values map to PackageTypes
    this._updatePackageCompatibility();
    this._applyPackageFilter();
    this._recalculateQuotes(); // Recalculate quotes for the new set of kindFilteredProducts
    this.resetFiltersAndSort(); // Reset filters when package changes
    this.showPlansTable = true; // Ensure table is visible
  }

  private _applyPackageFilter(): void {
    if (this.planFilter != null) {
      this.kindFilteredProducts = this.sponsorProducts.filter(
        (p) => p.package_kinds?.includes(this.planFilter!), // Add null check for package_kinds
      );
    } else {
      this.kindFilteredProducts = [...this.sponsorProducts]; // No package filter, use all
    }
    // Note: The original code also set `this.filteredProducts = this.kindFilteredProducts;`
    // This seemed redundant if `filteredProducts` wasn't used elsewhere. Removed for now.
    // If it was used (e.g., in the commented-out filter step in recalculate), reconsider.
  }

  private _updatePackageCompatibility(): void {
    this.hasTierCompatibleType = false;
    this.hasRelationshipCompatibleType = false;
    if (this.planFilter != null) {
      this.hasRelationshipCompatibleType = this.isRelationshipPackageType(this.planFilter);
      this.hasTierCompatibleType = this.isTieredPackageType(this.planFilter);
    }
  }

  // --- General Filtering ---

  public selectedFilter(value: string | boolean, event: Event, type: FilterType): void {
    const target = event.target as HTMLInputElement;
    const isChecked = target.checked;

    const updateSelection = <T extends { key: string; value: string | boolean }>(
      list: T[],
      key: string,
      val: string | boolean,
    ) => {
      if (isChecked) {
        // Add only if the correct type and not already present
        if (typeof val === typeof list[0]?.value && !list.some((item) => item.value === val)) {
          list.push({ key, value: val } as T);
        }
      } else {
        const index = list.findIndex((item) => item.value === val);
        if (index > -1) list.splice(index, 1);
      }
    };

    switch (type) {
      case 'metalLevel':
        if (typeof value === 'string') updateSelection(this.selectedMetalLevels, FILTER_KEYS.METAL_LEVEL, value);
        break;
      case 'productType':
        if (typeof value === 'string') updateSelection(this.selectedProductTypes, FILTER_KEYS.PRODUCT_TYPE, value);
        break;
      case 'insuranceCompany':
        if (typeof value === 'string')
          updateSelection(this.selectedInsuranceCompanies, FILTER_KEYS.PROVIDER_NAME, value);
        break;
      case 'hsa':
        if (typeof value === 'boolean') updateSelection(this.selectedHSAs, FILTER_KEYS.HSA_ELIGIBLE, value);
        break;
    }
    this.applyFiltersAndUpdateDisplay();
  }

  public applyFiltersAndUpdateDisplay(): void {
    let filtered: QuotedProduct[] = [...this.defaultCarriers];

    // Apply categorical filters
    filtered = this._applyCategoricalFilters(filtered);

    // Apply range filters
    filtered = this._applyRangeFilters(filtered);

    this.filteredCarriers = filtered;
    this._updateFilterOptionsAndCounts(); // Update counts based on the *final* filtered list
  }

  private _applyCategoricalFilters(plans: QuotedProduct[]): QuotedProduct[] {
    const filterGroups = [
      { selectedItems: this.selectedMetalLevels, key: FILTER_KEYS.METAL_LEVEL },
      { selectedItems: this.selectedProductTypes, key: FILTER_KEYS.PRODUCT_TYPE },
      { selectedItems: this.selectedInsuranceCompanies, key: FILTER_KEYS.PROVIDER_NAME },
      { selectedItems: this.selectedHSAs, key: FILTER_KEYS.HSA_ELIGIBLE },
    ];

    let filteredPlans = plans;
    filterGroups.forEach((group) => {
      if (group.selectedItems.length > 0) {
        filteredPlans = filteredPlans.filter((plan) =>
          group.selectedItems.some((item) => plan.product_information[item.key] === item.value),
        );
      }
    });
    return filteredPlans;
  }

  private _applyRangeFilters(plans: QuotedProduct[]): QuotedProduct[] {
    let filteredPlans = plans;

    // Deductible Filters
    if (this.yearlyMedicalDeductibleFrom !== null) {
      filteredPlans = filteredPlans.filter((plan) => {
        const deductible = this._parseDeductible(plan.product_information.deductible);
        return deductible >= (this.yearlyMedicalDeductibleFrom ?? -Infinity);
      });
    }
    if (this.yearlyMedicalDeductibleTo !== null) {
      filteredPlans = filteredPlans.filter((plan) => {
        const deductible = this._parseDeductible(plan.product_information.deductible);
        return deductible <= (this.yearlyMedicalDeductibleTo ?? Infinity);
      });
    }

    // Premium Filters
    if (this.planPremiumsFrom !== null) {
      filteredPlans = filteredPlans.filter((plan) => plan.total_cost >= (this.planPremiumsFrom ?? -Infinity));
    }
    if (this.planPremiumsTo !== null) {
      filteredPlans = filteredPlans.filter((plan) => plan.total_cost <= (this.planPremiumsTo ?? Infinity));
    }

    return filteredPlans;
  }

  private _parseDeductible(deductibleString?: string): number {
    if (!deductibleString) return NaN;
    const num = parseInt(deductibleString.replace(/[$,]/g, ''), 10);
    return isNaN(num) ? NaN : num;
  }

  private _updateFilterOptionsAndCounts(): void {
    // Update options based on *default* carriers to show all possibilities
    const uniqueValues = <T>(items: T[]) => Array.from(new Set(items));

    this.metalLevelOptions = uniqueValues(
      this.defaultCarriers.map((p) => p.product_information.metal_level).filter((level): level is string => !!level), // Ensure level is defined and string
    ).sort();

    this.carriers = uniqueValues(this.defaultCarriers.map((p) => p.product_information.provider_name)).sort();

    this.products = uniqueValues(this.defaultCarriers.map((p) => p.product_information.product_type)).sort();

    this.hsaEligible = uniqueValues(this.defaultCarriers.map((p) => p.product_information.hsa_eligible)).sort((a, b) =>
      a === b ? 0 : a ? -1 : 1,
    ); // Show true before false

    // Update count based on *currently filtered* carriers
    this.filterLength = this.filteredCarriers.length;
    this.filterSelected = this.defaultCarriers.length > 0; // Enable if we have data
    console.log('[PlanFilterComponent] Filters updated. Filter length:', this.filterLength);
  }

  public resetFiltersAndSort(): void {
    this.selectedMetalLevels = [];
    this.selectedProductTypes = [];
    this.selectedInsuranceCompanies = [];
    this.selectedHSAs = [];
    this.yearlyMedicalDeductibleFrom = null;
    this.yearlyMedicalDeductibleTo = null;
    this.planPremiumsFrom = null;
    this.planPremiumsTo = null;

    // Reset UI checkboxes
    document.querySelectorAll<HTMLInputElement>('.checkbox-input').forEach((checkbox) => (checkbox.checked = false));

    // Reset sorting
    this.sortDirection = true;
    this.sortKind = DEFAULT_SORT_KIND;
    this.iconSelected = DEFAULT_ICON_COL;

    // Re-apply filters (which will now be empty) to reset the displayed list
    this.applyFiltersAndUpdateDisplay();
  }

  // Helper method for string operations
  public isPercentageValue(value: any): boolean {
    return String(value).includes('%');
  }

  // --- Sorting ---

  public sortData(kind: SortKey): void {
    if (this.sortKind === kind) {
      this.sortDirection = !this.sortDirection; // Toggle direction
    } else {
      this.sortKind = kind;
      this.sortDirection = true; // Default to ascending
    }
    this.setIcon(kind); // Update icon state
    // Note: Sorting is handled by the OrderByPipe in the template based on sortKind and sortDirection
  }

  get sortFilter(): 'asc' | 'desc' {
    return this.sortDirection ? 'asc' : 'desc';
  }

  setIcon(col: SortKey): void {
    // This seems fragile if column IDs change. Consider a different approach if possible.
    // If 'col-6' etc. refers to CSS classes for layout, this logic is mixing concerns.
    // For now, keeping the original logic but using the type.
    this.iconSelected = col as string; // Cast needed if col can be keys not directly used as icon identifiers
  }

  showIcon(col: SortKey): boolean {
    // Show icon if it's the currently selected column for sorting
    return this.iconSelected === (col as string);
  }

  // --- UI Helpers / Template Methods ---

  public getToolTip(type: string): string | undefined {
    const currentPlanType = this.planType();
    const tipsForType = this.tooltips[currentPlanType];
    if (!tipsForType) return undefined;
    const tooltipObj = tipsForType.find((item: any) => item[type]); // Use any temporarily if structure is dynamic
    return tooltipObj ? tooltipObj[type] : undefined;
  }

  public getTableHeader(col: string): string[] {
    const currentPlanType = this.planType();
    const headersForType = this.tableHeaders[currentPlanType];
    if (!headersForType) return [];
    const headerObj = headersForType.find((item: any) => item[col]); // Use any temporarily
    return headerObj ? [headerObj[col]] : [];
  }

  public metalLevelCount(metalLevel: string): string | undefined {
    // Count based on *currently filtered* carriers for display
    if (this.planType() !== 'health') return undefined;
    const count = this.filteredCarriers.filter((p) => p.product_information.metal_level === metalLevel).length;
    return `(${count} Plans)`;
  }

  public productTypeCounts(product: string): string {
    const count = this.filteredCarriers.filter((p) => p.product_information.product_type === product).length;
    return `(${count} Plans)`;
  }

  public hsaCounts(hsa: boolean): string {
    const count = this.filteredCarriers.filter((p) => p.product_information.hsa_eligible === hsa).length;
    return `(${count} Plans)`;
  }

  public validateNumber(event: KeyboardEvent): boolean {
    const charCode = event.which ?? event.keyCode;
    // Allow backspace, delete, arrows, home, end, etc. (control keys) and numbers
    const isControlKey = charCode < 32 || (charCode >= 37 && charCode <= 40); // Basic control keys
    const isNumber = charCode >= 48 && charCode <= 57;

    if (isControlKey || isNumber) {
      return true;
    } else {
      event.preventDefault();
      return false;
    }
  }

  // --- Actions ---

  public downloadPdf(): void {
    const table = document.getElementById('plan-table');
    if (!table) {
      console.error("Element with ID 'plan-table' not found.");
      Swal.fire('Error', 'Could not find table to generate PDF.', 'error');
      return;
    }

    this.pdfView = true; // Indicate PDF generation is in progress (for UI state if needed)
    this._showPdfGenerationMsg();

    const filename = `${this.planType() || 'download'}.pdf`;

    html2PDF(table, {
      jsPDF: { unit: 'pt', format: 'a4', orientation: 'landscape' }, // Consider landscape if table is wide
      imageType: 'image/png',
      output: filename, // Let save() handle download name
      html2canvas: { scale: 2, useCORS: true }, // Improve quality, allow external images
      margin: { top: 40, right: 40, bottom: 40, left: 40 },
    })
      .then((pdf: any) => {
        // Use 'any' if jspdf types are not available
        pdf.save(filename);
        Swal.close();
        this.pdfView = false;
      })
      .catch((error: unknown) => {
        console.error('PDF generation failed:', error);
        Swal.fire('Error', 'PDF generation failed. Please try again.', 'error');
        this.pdfView = false;
      });
  }

  private _showPdfGenerationMsg(): void {
    Swal.fire({
      title: 'Generating PDF',
      html: 'Please hold while the PDF is generated.<br>This may take a moment...',
      icon: 'info',
      showConfirmButton: false,
      allowOutsideClick: false,
      didOpen: () => {
        Swal.showLoading();
      },
    });
  }

  public getSbcDocument(key: string): void {
    const win = window.open('', '_blank');
    if (win) {
      // Ensure PlanProviderService handles opening the doc in the new window
      this.planService.getSbcDocumentFor(key, win);
    } else {
      console.error('Could not open new window for SBC document.');
      Swal.fire('Error', "Could not open a new window. Please check your browser's pop-up blocker settings.", 'error');
    }
  }

  // --- Utility / Compatibility ---

  private isRelationshipPackageType(pt: PackageTypes): boolean {
    return this.clientPreferences.relationship_package_types.includes(pt);
  }

  private isTieredPackageType(pt: PackageTypes): boolean {
    return this.clientPreferences.tiered_package_types.includes(pt);
  }

  // Original will_enroll - Check if still needed, seems specific to roster processing which is now internal
  // public will_enroll(kind: string): boolean {
  //   const currentPlanType = this.planType();
  //   if (!currentPlanType) return false;
  //   return kind === '' || kind === 'both' || kind.includes(currentPlanType);
  // }

  // Original planOptions - Check if used in the template or can be removed
  public planOptions = [
    { key: 'single_issuer', value: 'One Carrier', view: 'health' },
    { key: 'metal_level', value: 'One Level', view: 'health' },
    { key: 'single_product', value: 'One Plan', view: 'health' },
    { key: 'single_product', value: 'One Plan', view: 'dental' },
  ];

  // Original selected property - Check if used or can be removed
  // selected = -1;
}
