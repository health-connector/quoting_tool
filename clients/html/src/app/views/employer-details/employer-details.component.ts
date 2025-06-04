import { Component, OnInit, ElementRef, inject, viewChild } from '@angular/core';
import {
  FormBuilder,
  Validators,
  FormArray,
  FormGroup,
  FormsModule,
  ReactiveFormsModule,
  FormControl,
} from '@angular/forms';
import { trigger, state, style, animate, transition } from '@angular/animations';
import {
  NgbModal,
  NgbAlert,
  NgbDropdown,
  NgbDropdownToggle,
  NgbDropdownMenu,
  NgbDropdownItem,
  NgbInputDatepicker,
  NgbDateStruct,
  NgbDatepickerConfig,
} from '@ng-bootstrap/ng-bootstrap';
import * as XLSX from 'xlsx';
import Swal from 'sweetalert2';

import { EmployerDetailsService } from '../../services/employer-details.service';
import zipcodesData from '../../../data/zipCode.json';
import sicsData from '../../../data/sic.json';
import sicCodesData from '../../../data/sicCodes.json';
import { SelectedSicService } from '../../services/selected-sic.service';
import { CoverageTypePipe } from '../../pipes/coverage-type.pipe';
import { RouterLink } from '@angular/router';
import { NgxDatatableModule } from '@swimlane/ngx-datatable';
import { DropdownTreeviewSelectComponent } from '../../components/dropdown-treeview-select/dropdown-treeview-select.component';
import { AutocompleteLibModule } from 'angular-ng-autocomplete';
import { NavComponent } from '../../components/nav/nav.component';
import { DatePipe } from '@angular/common';

interface ZipCodeData {
  zipCode: string;
  county: string;
}

interface SimpleSicCode {
  standardIndustryCodeCode: string;
  standardIndustryCodeFull?: string;
}

interface DetailedSicCode {
  StandardIndustryCode_Code: number;
  StandardIndustryCode_Full: string;
}

interface SicCodeInternal {
  standardIndustryCodeCode: string;
  standardIndustryCodeFull?: string;
}

interface Dependent {
  firstName: string;
  lastName: string;
  dob: Date | string;
  relationship: string;
}

interface Employee {
  firstName: string;
  lastName: string;
  dob: Date | string;
  coverageKind: string;
  dependents: Dependent[];
}

interface EmployerDetails {
  effectiveDate: Date | string;
  sic: SicCodeInternal;
  zip: string;
  county: string;
  employees: Employee[];
}

interface ParsedExcelRow {
  relation: string;
  lastName: string;
  firstName: string;
  dob: Date;
}

type ExcelRowData = (string | number | null)[];
type AOA = ExcelRowData[];

interface Alert {
  type: string;
  feature: string;
  enabled: boolean;
  message: string;
}

interface SicTreeItem {
  text: string;
  value: unknown;
}

interface EmployeeFormGroup {
  firstName: FormControl<string | null>;
  lastName: FormControl<string | null>;
  dob: FormControl<NgbDateStruct | null>;
  coverageKind: FormControl<string | null>;
  dependents: FormArray<FormGroup<DependentFormGroup>>;
}

interface DependentFormGroup {
  firstName: FormControl<string | null>;
  lastName: FormControl<string | null>;
  dob: FormControl<NgbDateStruct | null>;
  relationship: FormControl<string | null>;
}

// Define interface for effective date options
interface EffectiveDateOption {
  value: string;
  disabled: boolean;
}

const zipcodes: ZipCodeData[] = zipcodesData as ZipCodeData[];
const sics: SimpleSicCode[] = sicsData as SimpleSicCode[];
const sicCodes: DetailedSicCode[] = sicCodesData as unknown as DetailedSicCode[];

@Component({
  selector: 'app-employer-details',
  templateUrl: './employer-details.component.html',
  styleUrls: ['./employer-details.component.scss'],
  providers: [NgbModal, EmployerDetailsService],
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
    NgbAlert,
    NavComponent,
    FormsModule,
    ReactiveFormsModule,
    AutocompleteLibModule,
    DropdownTreeviewSelectComponent,
    NgxDatatableModule,
    NgbDropdown,
    NgbDropdownToggle,
    NgbDropdownMenu,
    NgbDropdownItem,
    NgbInputDatepicker,
    RouterLink,
    DatePipe,
    CoverageTypePipe,
  ],
  host: { '(window:beforeunload)': 'unloadHandler($event)' },
})
export class EmployerDetailsComponent implements OnInit {
  private fb = inject(FormBuilder);
  private modalService = inject(NgbModal);
  private employerDetailsService = inject(EmployerDetailsService);
  private dpConfig = inject(NgbDatepickerConfig);
  private selectedSicService = inject(SelectedSicService);

  rows: Employee[] = [];
  alerts: Alert[];
  model: NgbDateStruct;
  date: { months: number; day: number; year: number };
  sicKeyword = 'standardIndustryCodeCode';
  zipKeyword = 'zipCode';
  sics: SimpleSicCode[] = sics;
  zipcodes: string[] = [];
  availableCounties: ZipCodeData[] = zipcodes;
  defaultSelect: boolean = false;
  employerDetails: EmployerDetails | null = null;
  showEditHousehold: boolean = false;
  sicCodesForTree: DetailedSicCode[] = sicCodes;
  isLateRates: boolean = false;

  public counties: ZipCodeData[] = [];
  public quoteForm: FormGroup<{
    effectiveDate: FormControl<string | Date | null>;
    sic: FormControl<string | null>;
    zip: FormControl<string | null>;
    county: FormControl<string | null>;
    employees: FormArray<FormGroup<EmployeeFormGroup>>;
  }>;
  public editEmployeeForm: FormGroup<EmployeeFormGroup>;
  public addNewEmployeeForm: FormGroup<EmployeeFormGroup>;

  public editEmployeeIndex: number | null = null;
  public showEmployeeRoster = false;
  public showHouseholds = true;
  public employeeRoster: string | null = null;
  public employees: Employee[] = [];
  public effectiveDateOptions: EffectiveDateOption[] = [];
  public months: string[];
  public todaysDate = new Date();
  public employeeRosterDetails: string[];
  public showSicDetails: boolean = false;
  showNewEmployee = false;
  excelArray: ParsedExcelRow[] = [];

  // Date constraints for template use
  public minDateForTemplate: NgbDateStruct;
  public maxDateForTemplate: NgbDateStruct;

  relationOptions = [
    { key: 'Spouse', value: 'Spouse' },
    { key: 'Domestic Partner', value: 'Domestic Partner' },
    { key: 'Child', value: 'Child' },
  ];

  config = {
    hasFilter: true,
    decoupleChildFromParent: true,
  };

  file = viewChild<ElementRef<HTMLInputElement>>('file');

  unloadHandler(event: BeforeUnloadEvent) {
    event.preventDefault();
    event.returnValue = '';
  }

  constructor() {
    this.setAlerts();

    this.quoteForm = this.fb.group({
      effectiveDate: new FormControl<Date | string | null>(null, Validators.required),
      sic: new FormControl<string | null>('', Validators.required),
      zip: new FormControl<string | null>('', Validators.required),
      county: new FormControl<string | null>(''),
      employees: this.fb.array<FormGroup<EmployeeFormGroup>>([], Validators.required),
    });

    this.editEmployeeForm = this.fb.group({
      firstName: new FormControl<string | null>('', Validators.required),
      lastName: new FormControl<string | null>('', Validators.required),
      dob: new FormControl<NgbDateStruct | null>(null, Validators.required),
      coverageKind: new FormControl<string | null>('', Validators.required),
      dependents: this.fb.array<FormGroup<DependentFormGroup>>([]),
    });

    this.addNewEmployeeForm = this.fb.group({
      firstName: new FormControl<string | null>('', Validators.required),
      lastName: new FormControl<string | null>('', Validators.required),
      dob: new FormControl<NgbDateStruct | null>(null, Validators.required),
      coverageKind: new FormControl<string | null>('', Validators.required),
      dependents: this.fb.array<FormGroup<DependentFormGroup>>([]),
    });

    this.months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    this.employeeRosterDetails = [
      'Name',
      'Date of Birth',
      'Dependent Name(s), if any',
      'Dependent Relationship(s)',
      'Dependent Date of Birth(s)',
    ];

    const currentDate = new Date();
    const currentYear = currentDate.getFullYear();
    const currentMonth = currentDate.getMonth() + 1; // getMonth() returns 0-11, so add 1
    const currentDay = currentDate.getDate();

    // Configure datepicker for easy navigation when selecting birth dates for people over 100 years old
    this.dpConfig.minDate = { year: currentYear - 110, month: 1, day: 1 };
    this.dpConfig.maxDate = { year: currentYear, month: currentMonth, day: currentDay };

    // Set date constraints for template use
    this.minDateForTemplate = { year: currentYear - 110, month: 1, day: 1 };
    this.maxDateForTemplate = { year: currentYear, month: currentMonth, day: currentDay };
    this.dpConfig.navigation = 'select'; // Enable year and month dropdown selectors
    this.dpConfig.displayMonths = 1; // Display one month at a time for better focus
    this.dpConfig.outsideDays = 'collapsed'; // Hide days from other months
    this.dpConfig.weekdays = true; // Show weekday headers
    this.dpConfig.showWeekNumbers = false; // Hide week numbers to save space
  }

  ngOnInit() {
    this.getZipCodes();
    this.selectedSicService.currentMessage.subscribe((item: SicTreeItem | string) => this.setSicFromTree(item));
    this.employeeRoster = localStorage.getItem('employerDetails');
    if (this.employeeRoster) {
      this.showEmployeeRoster = true;
      const storedDetails: EmployerDetails = JSON.parse(this.employeeRoster);
      this.employerDetails = storedDetails;

      this.quoteForm.patchValue({
        effectiveDate: this.employerDetails.effectiveDate,
        zip: this.employerDetails.zip,
        sic: this.employerDetails.sic?.standardIndustryCodeCode || '',
        county: this.employerDetails.county,
      });

      this.counties = this.availableCounties.filter((county) => county.zipCode === this.employerDetails?.zip);
      if (this.counties.length > 0 && this.employerDetails) {
        this.quoteForm.get('county')?.setValue(this.employerDetails.county);
      }
      this.loadEmployeesFromStorage();
    }

    let dates: string[] = [];
    let is_late_rate = false;
    this.employerDetailsService.getStartOnDates().subscribe((response) => {
      dates = response['dates'] as string[];
      is_late_rate = response['is_late_rate'] as boolean;
      this.isLateRates = is_late_rate;
      this.effectiveDateOptions = dates.map((dateStr) => ({
        value: dateStr,
        disabled: is_late_rate,
      }));
    });
  }

  close(alert: Alert) {
    this.alerts.splice(this.alerts.indexOf(alert), 1);
  }

  setAlerts() {
    this.alerts = [
      {
        type: 'warning',
        feature: 'Late rates',
        enabled: true,
        message:
          'Due to a delay, premiums for some coverage effective dates are not available yet. Please check again soon to see if this information has been updated. You can also contact Customer Service or your broker if you need help.',
      },
    ];
  }

  getZipCodes() {
    const zipCodes = [];
    zipcodes.map((zipcode) => zipCodes.push(zipcode.zipCode));
    this.zipcodes = zipCodes.reduce((unique, item) => (unique.includes(item) ? unique : [...unique, item]), []);
  }

  setCounty(value) {
    this.quoteForm.get('county').setValue(value);
  }

  setSicFromTree(item: SicTreeItem | string) {
    if (item !== 'default item' && typeof item !== 'string') {
      const sicValue = this.sics.filter((sic) => sic['standardIndustryCodeFull'] === item.text)[0][
        'standardIndustryCodeCode'
      ];
      this.quoteForm.get('sic').setValue(sicValue);
      this.showSicDetails = false;
    }
  }

  isSelected(dateValue: string): boolean {
    if (this.employerDetails?.effectiveDate) {
      const storedDate =
        this.employerDetails.effectiveDate instanceof Date
          ? this.employerDetails.effectiveDate.toISOString().split('T')[0]
          : String(this.employerDetails.effectiveDate);
      const optionDate = dateValue;
      return storedDate === optionDate;
    } else {
      return false;
    }
  }

  checkFilePresence(file: HTMLInputElement) {
    const uploadBtn = document.getElementById('file-upload-btn');
    if (uploadBtn) {
      if (file.files && file.files.length) {
        uploadBtn.removeAttribute('disabled');
      } else {
        uploadBtn.setAttribute('disabled', 'true');
      }
    }
  }

  addEmployee() {
    const control = <FormArray>this.quoteForm.controls.employees;
    control.push(
      this.fb.group<EmployeeFormGroup>({
        firstName: new FormControl<string | null>('', Validators.required),
        lastName: new FormControl<string | null>('', Validators.required),
        dob: new FormControl<NgbDateStruct | null>(null, Validators.required),
        coverageKind: new FormControl<string | null>('', Validators.required),
        dependents: this.fb.array<FormGroup<DependentFormGroup>>([]),
      }),
    );
  }

  addNewEmployee() {
    this.showNewEmployee = true;
  }

  deleteEmployee(index) {
    const control = <FormArray>this.quoteForm.controls.employees;
    control.removeAt(index);
  }

  addDependent(control) {
    control.push(
      this.fb.group<DependentFormGroup>({
        firstName: new FormControl<string | null>('', Validators.required),
        lastName: new FormControl<string | null>('', Validators.required),
        dob: new FormControl<NgbDateStruct | null>(null, Validators.required),
        relationship: new FormControl<string | null>('', Validators.required),
      }),
    );
  }

  deleteDependent(control, index) {
    control.removeAt(index);
  }

  onSubmit() {
    // console.log(this.quoteForm.value);
  }

  open(content) {
    this.modalService.open(content);
  }

  fileUploaded(fileInfo) {
    const input = new FormData();
    const uploadedFile = fileInfo.files[0];

    if (uploadedFile.type !== 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet') {
      Swal.fire({
        icon: 'error',
        title: 'Invalid file type',
        text: 'Please use the Roster Template to upload a vaild excel file.',
      });
      return;
    }

    input.append('file', fileInfo.files[0]);

    this.employerDetailsService.postUpload(input).subscribe();
    // Below is used to display in the UI
    const reader: FileReader = new FileReader();
    reader.onload = (e: ProgressEvent<FileReader>) => {
      const target = e.target as FileReader;
      if (typeof target.result !== 'string') {
        Swal.fire('Error', 'Failed to read file content.', 'error');
        console.error('FileReader result is not a string:', target.result);
        return;
      }
      /* read workbook */
      const bstr: string = target.result;
      const wb: XLSX.WorkBook = XLSX.read(bstr, { type: 'binary' });

      /* grab first sheet */
      const wsname: string = wb.SheetNames[0];
      const ws: XLSX.WorkSheet = wb.Sheets[wsname];

      /* save data */
      const data = XLSX.utils.sheet_to_json(ws, { header: 1 }) as AOA;
      const dataFromArray: ParsedExcelRow[] = [];
      data.forEach((d, i) => {
        // Skip header rows (assuming first 3 rows are headers) and empty rows
        if (i > 2 && d.length > 8) {
          // Check length before accessing index 8
          const relation = d[1];
          const lastName = d[2];
          const firstName = d[3];
          const dobExcel = d[8];

          // Validate types before processing
          if (
            typeof relation === 'string' &&
            typeof lastName === 'string' &&
            typeof firstName === 'string' &&
            typeof dobExcel === 'number' // Check if dob is a number (Excel date)
          ) {
            try {
              const dob = this.getJsDateFromExcel(dobExcel);
              // Check if the date is valid after conversion
              if (!isNaN(dob.getTime())) {
                dataFromArray.push({ relation, lastName, firstName, dob });
              } else {
                console.warn(`Invalid date calculated for row ${i + 1}:`, dobExcel);
                // Optionally notify the user about the specific row
              }
            } catch (dateError) {
              console.error(`Error processing date for row ${i + 1}:`, dobExcel, dateError);
            }
          } else {
            console.warn(`Skipping row ${i + 1} due to unexpected data types:`, d);
            // Optionally notify the user about skipped rows
          }
        }
      });
      this.excelArray = dataFromArray;
    };
    reader.readAsBinaryString(fileInfo.files[0]);
    setTimeout(() => {
      this.parseResults(this.excelArray);
    }, 500);
  }

  zipChangeSearch(event) {
    if (event.length === 5) {
      this.counties = this.availableCounties.filter((zipcode) => zipcode.zipCode === event);
      this.quoteForm.get('county')?.setValue(this.counties[0].county);
      this.enableCounty();
    }
    if (event.length === 5 && this.showEmployeeRoster) {
      this.updateFormValue(event, 'zipCode');
    }
  }

  selectEvent(item) {
    this.getCounties(item);
    if (this.showEmployeeRoster) {
      this.updateFormValue(item, 'zipCode');
    }
    this.counties = this.availableCounties.filter((zipcode) => zipcode.zipCode === item);
    this.quoteForm.get('county')?.setValue(this.counties[0].county);
  }

  updateEffectiveDate(event: Event) {
    const target = event.target as HTMLSelectElement;
    const value = target.value;
    if (this.showEmployeeRoster) {
      this.updateFormValue(value, 'effectiveDate');
    }
  }

  updateSic(event: SimpleSicCode) {
    if (this.showEmployeeRoster) {
      this.updateFormValue(event, 'sic');
    }
  }

  updateChangedSic(event) {
    let selectedSic;
    if (event.length === 4) {
      selectedSic = this.sics.find((sic) => sic.standardIndustryCodeCode === event);
    }
    if (selectedSic && this.showEmployeeRoster) {
      this.updateFormValue(selectedSic, 'sic');
    }
  }

  updateFormValue(event: string | SimpleSicCode, type: 'zipCode' | 'effectiveDate' | 'sic') {
    const detailsStr = localStorage.getItem('employerDetails');
    if (!detailsStr) return;
    const form = JSON.parse(detailsStr) as EmployerDetails;

    if (type === 'zipCode' && typeof event === 'string') {
      form.zip = event;
      this.counties = this.availableCounties.filter((zipcode) => zipcode.zipCode === event);
      if (this.counties.length > 0) {
        form.county = this.counties[0].county;
      }
      localStorage.setItem('employerDetails', JSON.stringify(form));
      this.enableCounty();
    } else if (type === 'effectiveDate' && typeof event === 'string') {
      form.effectiveDate = event;
      localStorage.setItem('employerDetails', JSON.stringify(form));
    } else if (type === 'sic' && typeof event !== 'string') {
      form.sic = event;
      localStorage.setItem('employerDetails', JSON.stringify(form));
    }
  }

  getCounties(item) {
    this.counties = this.availableCounties.filter((zipcode) => zipcode.zipCode === item);
    if (this.showEmployeeRoster) {
      const form = JSON.parse(localStorage.getItem('employerDetails'));
      if (this.counties.length === 1) {
        form.county = this.counties[0].county;
        localStorage.setItem('employerDetails', JSON.stringify(form));
        this.quoteForm.get('county')?.setValue(form.county.county);
      }
    }
    if (!this.showEmployeeRoster && this.counties.length) {
      this.quoteForm.get('county')?.setValue(this.counties[0].county);
    }
    this.enableCounty();
  }

  updateCounty(event: Event) {
    const target = event.target as HTMLSelectElement;
    if (this.showEmployeeRoster) {
      const detailsStr = localStorage.getItem('employerDetails');
      if (!detailsStr) return;
      const form = JSON.parse(detailsStr) as EmployerDetails;
      const selectedCounty = this.availableCounties.find((c) => c.county === target.value && c.zipCode === form.zip);
      if (selectedCounty) {
        form.county = selectedCounty.county;
        localStorage.setItem('employerDetails', JSON.stringify(form));
      }
    }
  }

  enableCounty() {
    const countyField = document.getElementById('countyField');
    if (this.counties.length === 1) {
      this.defaultSelect = true;
    }

    if (this.counties.length > 1) {
      countyField.removeAttribute('disabled');
    } else {
      countyField.setAttribute('disabled', 'true');
    }
  }

  onChangeSearch() {
    // fetch remote data from here
    // And reassign the 'data' which is binded to 'data' property.
  }

  saveEmployerDetails(form) {
    localStorage.setItem('employerDetails', form);
  }

  onFocused(event) {
    const input = event.target;
    input.style.border = '1px solid #000';
    // do something when input is focused
  }

  getJsDateFromExcel(excelDate) {
    return new Date((excelDate - (25567 + 1)) * 86400 * 1000);
  }

  parseResults(excelArray) {
    this.modalService.dismissAll();
    let count = 0;
    const employeesControl = this.quoteForm.controls.employees as FormArray<FormGroup<EmployeeFormGroup>>;

    excelArray.forEach((data) => {
      // Convert DOB to ISO string immediately
      const dobString = this.convertNgbDateStructToISO(data.dob);
      // Convert ISO string to NgbDateStruct for the form control
      const dobStruct = this.convertISOToNgbDateStruct(dobString);

      if (data.relation === 'Employee') {
        count++;
        employeesControl.push(
          this.fb.group({
            firstName: new FormControl(data.firstName, Validators.required),
            lastName: new FormControl(data.lastName, Validators.required),
            dob: new FormControl(dobStruct, Validators.required), // Store as NgbDateStruct
            coverageKind: new FormControl('both', Validators.required),
            dependents: this.fb.array<FormGroup<DependentFormGroup>>([]),
          }),
        );
      } else {
        if (count > 0) {
          const employeeGroup = employeesControl.controls[count - 1];
          const dependentsArray = employeeGroup.controls.dependents as FormArray<FormGroup<DependentFormGroup>>;
          dependentsArray.push(
            this.fb.group({
              firstName: new FormControl(data.firstName, Validators.required),
              lastName: new FormControl(data.lastName, Validators.required),
              dob: new FormControl(dobStruct, Validators.required), // Store as NgbDateStruct
              relationship: new FormControl(data.relation, Validators.required),
            }),
          );
        } else {
          console.warn('Found dependent data before any employee data in Excel sheet:', data);
          // Handle case where dependent appears before employee if necessary
        }
      }
    });
    // Update rows with the form values which now contain NgbDateStruct for DOBs
    // Note: This might cause issues if other parts expect ISO strings in `rows`.
    // Consider if `rows` should store strings and only forms use NgbDateStruct.
    // For now, align rows with form structure:
  }

  createRoster() {
    const formValue = this.quoteForm.value;
    const detailsToSave = {
      ...formValue,
      effectiveDate: formValue.effectiveDate, // Keep effective date as-is since it's already a string from the select
      employees: (formValue.employees || []).map((emp) => ({
        ...emp,
        dob: this.convertNgbDateStructToISO(emp.dob),
        dependents: (emp.dependents || []).map((dep) => ({
          ...dep,
          dob: this.convertNgbDateStructToISO(dep.dob),
        })),
      })),
    };

    localStorage.setItem('employerDetails', JSON.stringify(detailsToSave));
    this.showHouseholds = false;
    this.ngOnInit();
  }

  saveNewEmployee() {
    const form = this.employerDetails;
    if (!form) {
      console.error('Cannot save new employee: employerDetails is null.');
      return; // Exit if employerDetails isn't loaded
    }

    const employees = form.employees;
    const rawFormValue = this.addNewEmployeeForm.value;

    // Convert NgbDateStruct to ISO string before creating the Employee object
    const newEmployee: Employee = {
      firstName: rawFormValue.firstName ?? '',
      lastName: rawFormValue.lastName ?? '',
      dob: this.convertNgbDateStructToISO(rawFormValue.dob), // Convert here
      coverageKind: rawFormValue.coverageKind ?? '',
      dependents: (rawFormValue.dependents || []).map((dep) => ({
        firstName: dep.firstName ?? '',
        lastName: dep.lastName ?? '',
        dob: this.convertNgbDateStructToISO(dep.dob), // Convert dependent DOB here
        relationship: dep.relationship ?? '',
      })),
    };

    employees.push(newEmployee); // Push the correctly typed object
    localStorage.setItem('employerDetails', JSON.stringify(form));

    // Update rows directly from the modified employerDetails
    this.loadEmployeesFromStorage(); // This will use the updated employerDetails with string dates

    this.showNewEmployee = false;
    this.addNewEmployeeForm.reset();
    // No need to call ngOnInit() here, loadEmployeesFromStorage updates the rows
  }

  resetForm() {
    localStorage.removeItem('employerDetails');
    this.showEmployeeRoster = false;
    this.quoteForm.reset();
  }

  loadEmployeesFromStorage() {
    if (this.employerDetails && this.employerDetails.employees) {
      this.rows = JSON.parse(JSON.stringify(this.employerDetails.employees));
    } else {
      this.rows = [];
    }
  }

  removeEmployeeFromRoster(rowIndex) {
    this.rows.splice(rowIndex, 1);
    this.employerDetails.employees.splice(rowIndex, 1);
    localStorage.setItem('employerDetails', JSON.stringify(this.employerDetails));
    this.loadEmployeesFromStorage();
  }

  editEmployee(rowIndex) {
    this.editEmployeeIndex = rowIndex;
    this.showEditHousehold = true;
    const employee = JSON.parse(JSON.stringify(this.rows[rowIndex]));
    const employeeForm = this.editEmployeeForm;

    const employeeDobStruct = this.convertISOToNgbDateStruct(employee.dob as string);

    employeeForm.patchValue({
      firstName: employee.firstName,
      lastName: employee.lastName,
      dob: employeeDobStruct,
      coverageKind: employee.coverageKind,
    });

    const dependentsArray = employeeForm.controls.dependents as FormArray<FormGroup<DependentFormGroup>>;
    dependentsArray.clear();

    employee.dependents.forEach((dependent) => {
      const dependentDobStruct = this.convertISOToNgbDateStruct(dependent.dob as string);
      dependentsArray.push(
        this.fb.group({
          firstName: new FormControl(dependent.firstName, Validators.required),
          lastName: new FormControl(dependent.lastName, Validators.required),
          dob: new FormControl(dependentDobStruct, Validators.required),
          relationship: new FormControl(dependent.relationship, Validators.required),
        }),
      );
    });
  }

  validateEmployeeEditForm() {
    const employeeFrom = this.editEmployeeForm;
    return employeeFrom.invalid || employeeFrom.controls.dependents.invalid;
  }

  private convertNgbDateStructToISO(date: NgbDateStruct | Date | string | null): string | null {
    if (!date) {
      return null;
    }
    if (date instanceof Date) {
      if (!isNaN(date.getTime())) {
        return date.toISOString().split('T')[0];
      } else {
        return null;
      }
    }
    if (typeof date === 'string') {
      const parsedDate = new Date(date);
      if (!isNaN(parsedDate.getTime())) {
        return parsedDate.toISOString().split('T')[0];
      }
      if (/^\d{4}-\d{2}-\d{2}$/.test(date)) {
        return date;
      }
      return null;
    }
    if (typeof date === 'object' && date !== null && 'year' in date && 'month' in date && 'day' in date) {
      if (date.year && date.month && date.day) {
        const year = date.year;
        const month = date.month.toString().padStart(2, '0');
        const day = date.day.toString().padStart(2, '0');
        return `${year}-${month}-${day}`;
      } else {
        return null;
      }
    }
    console.warn('Could not convert date value:', date);
    return null;
  }

  updateEmployee() {
    this.showEditHousehold = false;
    const formValue = this.editEmployeeForm.value;

    const updatedEmployee: Employee = {
      firstName: formValue.firstName ?? '',
      lastName: formValue.lastName ?? '',
      dob: this.convertNgbDateStructToISO(formValue.dob),
      coverageKind: formValue.coverageKind ?? '',
      dependents: (formValue.dependents || []).map((dep) => ({
        firstName: dep.firstName ?? '',
        lastName: dep.lastName ?? '',
        dob: this.convertNgbDateStructToISO(dep.dob),
        relationship: dep.relationship ?? '',
      })),
    };

    if (this.editEmployeeIndex !== null) {
      this.rows[this.editEmployeeIndex] = { ...updatedEmployee };

      if (this.employerDetails && this.employerDetails.employees) {
        this.employerDetails.employees[this.editEmployeeIndex] = { ...updatedEmployee };
        localStorage.setItem('employerDetails', JSON.stringify(this.employerDetails));
      }

      this.editEmployeeIndex = null;
      this.rows = [...this.rows];
    } else {
      console.error('editEmployeeIndex is null, cannot update employee.');
    }
  }

  validateMonthDate(str, max) {
    if (str.charAt(0) !== '0' || str === '00') {
      let num = parseInt(str, 10);
      if (isNaN(num) || num <= 0 || num > max) {
        num = 1;
      }
      str = num > parseInt(max.toString().charAt(0), 10) && num.toString().length === 1 ? '0' + num : num.toString();
    }
    return str;
  }

  formatInputDate(e) {
    let input = e.target.value;
    if (/\D\/$/.test(input)) {
      input = input.substr(0, input.length - 3);
    }

    const values = input.split('/').map(function (v) {
      return v.replace(/\D/g, '');
    });
    if (values[0]) {
      values[0] = this.validateMonthDate(values[0], 12);
    }
    if (values[1]) {
      values[1] = this.validateMonthDate(values[1], 31);
    }
    const output = values.map(function (v, i) {
      return v.length === 2 && i < 2 ? v + ' / ' : v;
    });
    e.target.value = output.join('').substr(0, 14);
  }

  private convertISOToNgbDateStruct(isoDate: string | null): NgbDateStruct | null {
    if (!isoDate || !/^\d{4}-\d{2}-\d{2}$/.test(isoDate)) {
      return null;
    }
    try {
      const date = new Date(isoDate + 'T00:00:00Z');
      if (isNaN(date.getTime())) return null;
      return {
        year: date.getUTCFullYear(),
        month: date.getUTCMonth() + 1,
        day: date.getUTCDate(),
      };
    } catch (e) {
      console.error('Error converting ISO string to NgbDateStruct:', isoDate, e);
      return null;
    }
  }
}
