import { Component, OnInit, ElementRef, ViewChild, HostListener } from '@angular/core';
import { FormBuilder, Validators, FormArray, FormGroup } from '@angular/forms';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { EmployerDetailsService } from './../services/employer-details.service';
import { trigger, state, style, animate, transition } from '@angular/animations';
import { NgbDateStruct, NgbDatepickerConfig } from '@ng-bootstrap/ng-bootstrap';
import zipcodes from '../../data/zipCode.json';
import sics from '../../data/sic.json';
import sicCodes from '../../data/sicCodes.json';
import { SelectedSicService } from '../services/selected-sic.service';
import * as XLSX from 'xlsx';
type AOA = any[][];
import Swal from 'sweetalert2';


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
          opacity: 0
        })
      ),
      transition('void <=> *', animate(400))
    ])
  ]
})
export class EmployerDetailsComponent implements OnInit {
  rows = [];
  model: NgbDateStruct;
  date: { months: number; day: number; year: number };
  sicKeyword = 'standardIndustryCodeCode';
  zipKeyword = 'zipCode';
  sics = sics;
  zipcodes = zipcodes;
  availableCounties = zipcodes;
  defaultSelect: boolean;
  uploadData: any;
  employee: any;
  employeeIndex: any;
  employerDetails: any;
  showEditHousehold: any;
  sicCodes = sicCodes;

  public counties: any;
  public quoteForm: FormGroup;
  public editEmployeeForm: FormGroup;
  public addNewEmployeeForm: FormGroup;
  public editEmployeeIndex: any;
  public showEmployeeRoster = false;
  public showHouseholds = true;
  public employeeRoster: any;
  public employees: any;
  public effectiveDateOptions: any;
  public months: any;
  public todaysDate = new Date();
  public employeeRosterDetails: any;
  public show: boolean;
  showNewEmployee = false;
  excelArray: any;

  relationOptions = [
    { key: 'Spouse', value: 'Spouse' },
    { key: 'Domestic Partner', value: 'Domestic Partner' },
    { key: 'Child', value: 'Child' },
    { key: 'Child', value: 'Disabled Child' }
  ];

  config = {
    hasFilter: true,
    decoupleChildFromParent: true
  };

  @ViewChild('file', { static: false }) file: ElementRef;

  @HostListener('window:beforeunload', ['$event']) unloadHandler(event: Event) {
    event.returnValue = false;
  }

  constructor(
    private fb: FormBuilder,
    private modalService: NgbModal,
    private employerDetailsService: EmployerDetailsService,
    private dpConfig: NgbDatepickerConfig,
    private selectedSicService: SelectedSicService
  ) {
    this.quoteForm = this.fb.group({
      effectiveDate: ['', Validators.required],
      sic: ['', Validators.required],
      zip: ['', Validators.required],
      county: [''],
      employees: this.fb.array([], Validators.required)
    });

    this.showEditHousehold = false;

    this.editEmployeeForm = this.fb.group({
      firstName: [''],
      lastName: [''],
      dob: ['', Validators.required],
      coverageKind: ['', Validators.required],
      dependents: this.fb.array([])
    });

    this.addNewEmployeeForm = this.fb.group({
      firstName: [''],
      lastName: [''],
      dob: ['', Validators.required],
      coverageKind: ['', Validators.required],
      dependents: this.fb.array([])
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
      'December'
    ];

    this.employeeRosterDetails = [
      'Name',
      'Date of Birth',
      'Dependent Name(s), if any',
      'Dependent Relationship(s)',
      'Dependent Date of Birth(s)'
    ];

    const year = new Date().getFullYear();

    this.dpConfig.minDate = { year: year - 110, month: 1, day: 1 };
    this.dpConfig.maxDate = { year: year + 1, month: 12, day: 31 };
  }

  ngOnInit() {
    this.getZipCodes();
    this.selectedSicService.currentMessage.subscribe((message) => this.setSicFromTree(message));
    this.employeeRoster = localStorage.getItem('employerDetails');
    if (this.employeeRoster) {
      this.showEmployeeRoster = true;
      this.employerDetails = JSON.parse(this.employeeRoster);
      this.quoteForm.get('effectiveDate').setValue(new Date(this.employerDetails.effectiveDate));
      this.quoteForm.get('zip').setValue(this.employerDetails.zip);
      this.quoteForm.get('sic').setValue(this.employerDetails.sic.standardIndustryCodeCode);
      this.quoteForm.get('county').setValue(this.employerDetails.county);
      this.counties = this.availableCounties.filter((county) => county.county === this.employerDetails.county);
      this.loadEmployeesFromStorage();
    }

    var dates = [] ;
    this.employerDetailsService.getStartOnDates().subscribe(function(response) {
      dates = response["dates"].map(date => dates.push(date));
    });
    this.effectiveDateOptions = dates;
  }

  getZipCodes() {
    const zipCodes = [];
    zipcodes.map(zipcode => zipCodes.push(zipcode.zipCode));
    this.zipcodes = zipCodes.reduce((unique, item) => (unique.includes(item) ? unique : [...unique, item]), []);
  }

  setCounty(value) {
    this.quoteForm.get('county').setValue(value);
  }

  setSicFromTree(item) {
    if (item !== 'default item') {
      const sicValue = this.sics.filter((sic) => sic['standardIndustryCodeFull'] === item.text)[0][
        'standardIndustryCodeCode'
      ];
      this.quoteForm.get('sic').setValue(sicValue);
      this.show = false;
    }
  }

  isSelected(date) {
    if (this.employerDetails && date.toString() === this.employerDetails.effectiveDate) {
      return true;
    } else {
      return false;
    }
  }

  checkFilePresence(file) {
    if (file.files.length) {
      document.getElementById('file-upload-btn').removeAttribute('disabled');
    }
  }

  addEmployee() {
    const control = <FormArray>this.quoteForm.controls.employees;
    control.push(
      this.fb.group({
        firstName: [''],
        lastName: [''],
        dob: ['', Validators.required],
        coverageKind: ['', Validators.required],
        dependents: this.fb.array([])
      })
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
      this.fb.group({
        firstName: [''],
        lastName: [''],
        dob: ['', Validators.required],
        relationship: ['', Validators.required]
      })
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
        text: 'Please use the Roster Template to upload a vaild excel file.'
      });
      return;
    }

    input.append('file', fileInfo.files[0]);

    this.employerDetailsService.postUpload(input).subscribe();
    // Below is used to display in the UI
    const reader: FileReader = new FileReader();
    reader.onload = (e: any) => {
     /* read workbook */
     const bstr: string = e.target.result;
     const wb: XLSX.WorkBook = XLSX.read(bstr, {type: 'binary'});

     /* grab first sheet */
     const wsname: string = wb.SheetNames[0];
     const ws: XLSX.WorkSheet = wb.Sheets[wsname];

     /* save data */
     const data = <AOA>(XLSX.utils.sheet_to_json(ws, {header: 1}));
     const dataFromArray = [];
     data.map((d, i) => {
       if (i > 2 && d.length > 0) {
         dataFromArray.push({relation: d[1], lastName: d[2], firstName: d[3], dob: this.getJsDateFromExcel(d[8])});
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
      this.quoteForm.get('county').setValue(this.counties[0].county);
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
    this.quoteForm.get('county').setValue(this.counties[0].county);
  }

  updateEffectiveDate(event) {
    if (this.showEmployeeRoster) {
      this.updateFormValue(event, 'effectiveDate');
    }
  }

  updateSic(event) {
    if (this.showEmployeeRoster) {
      this.updateFormValue(event, 'sic');
    }
  }

  updateChangedSic(event) {
    let selectedSic;
    if (event.length === 4) {
      selectedSic = this.sics.find(sic => sic.standardIndustryCodeCode === event);
    }
    if (selectedSic && this.showEmployeeRoster) {
      this.updateFormValue(selectedSic, 'sic');
    }
  }

  updateFormValue(event, type) {
    if (type === 'zipCode') {
      const form = JSON.parse(localStorage.getItem('employerDetails'));
      form.zip = event;
      this.counties = this.availableCounties.filter((zipcode) => zipcode.zipCode === event);
      form.county = this.counties[0].county;
      localStorage.setItem('employerDetails', JSON.stringify(form));
      this.enableCounty();
    }
    if (type === 'effectiveDate') {
      const form = JSON.parse(localStorage.getItem('employerDetails'));
      form.effectiveDate = event;
      localStorage.setItem('employerDetails', JSON.stringify(form));
    }
    if (type === 'sic') {
      const form = JSON.parse(localStorage.getItem('employerDetails'));
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
        this.quoteForm.get('county').setValue(form.county.county);
      }
    }
    if (!this.showEmployeeRoster && this.counties.length) {
      this.quoteForm.get('county').setValue(this.counties[0].county);
    }
    this.enableCounty();
  }

  updateCounty(event) {
    if (this.showEmployeeRoster) {
      const form = JSON.parse(localStorage.getItem('employerDetails'));
      const selectedCounty = this.availableCounties.filter((c) => c.county === event.target.value && c.zipCode === form.zip);
      form.county = selectedCounty[0].county;
      localStorage.setItem('employerDetails', JSON.stringify(form));
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
    // do something when input is focused
  }

  getJsDateFromExcel(excelDate) {
    return new Date((excelDate - (25567 + 1)) *  86400 * 1000);
  }

  parseResults(excelArray) {
    this.modalService.dismissAll();
    let count = 0;

    excelArray.map((data) => {
      const control = <FormArray>this.quoteForm.controls.employees;
      if (data.relation === 'Employee') {
        count++;
        control.push(
          this.fb.group({
            firstName: data.firstName,
            lastName: data.lastName,
            dob: new Date(data.dob.getFullYear(), data.dob.getMonth(), data.dob.getDate()),
            coverageKind: ['both'],
            dependents: this.fb.array([])
          })
        );
      } else {
        // Add dependents to employee if dependents
        control['controls'][count - 1]['controls']['dependents'].push(
          this.fb.group({
            firstName: data.firstName,
            lastName: data.lastName,
            dob: new Date(data.dob.getFullYear(), data.dob.getMonth(), data.dob.getDate()),
            relationship: data.relation
          })
        );
      }
    });
  }

  createRoster() {
    // Adds the uploaded roster to localStorage
    localStorage.setItem('employerDetails', JSON.stringify(this.quoteForm.value));
    this.showHouseholds = false;
    this.ngOnInit();
  }

  saveNewEmployee() {
    const form = this.employerDetails;
    const employees = form.employees;
    const newEmployee = this.addNewEmployeeForm.value;
    employees.push(newEmployee);
    localStorage.setItem('employerDetails', JSON.stringify(form));
    this.rows = employees;
    this.showNewEmployee = false;
    this.addNewEmployeeForm.reset();
    this.ngOnInit();
  }

  resetForm() {
    // Removes the roster from localStorage
    localStorage.removeItem('employerDetails');
    this.showEmployeeRoster = false;
    this.quoteForm.reset();
  }

  loadEmployeesFromStorage() {
    // Loads the roster from localStorage if present
    const roster = JSON.parse(this.employeeRoster);
    this.employees = roster;
    this.rows = roster.employees;
  }

  removeEmployeeFromRoster(rowIndex) {
    this.rows.splice(rowIndex, 1);
    this.employerDetails.employees.splice(rowIndex, 1);
    localStorage.setItem('employerDetails', JSON.stringify(this.employerDetails));
  }

  editEmployee(rowIndex) {
    // this.editEmployeeForm.reset();
    this.editEmployeeIndex = rowIndex;
    this.showEditHousehold = true;
    const employee = this.rows[rowIndex];
    const employeeForm = this.editEmployeeForm;
    const currentContext = this;
    employeeForm.patchValue({
      firstName: employee.firstName,
      lastName: employee.lastName,
      dob: new Date(Date.parse(employee.dob)),
      coverageKind: employee.coverageKind
    });
    employeeForm.controls.dependents = this.fb.array([]);
    employee.dependents.forEach(function(dependent) {
      (<FormArray>employeeForm.controls.dependents).push(
        currentContext.fb.group({
          firstName: [dependent.firstName],
          lastName: [dependent.lastName],
          dob: [new Date(Date.parse(dependent.dob)), Validators.required],
          relationship: [dependent.relationship, Validators.required]
        })
      );
    });
  }

  validateEmployeeEditForm() {
    const employeeFrom = this.editEmployeeForm;
    return employeeFrom.invalid || employeeFrom.controls.dependents.invalid;
  }

  updateEmployee() {
    this.showEditHousehold = false;
    this.rows[this.editEmployeeIndex] = this.editEmployeeForm.value;
    this.employerDetails.employees[this.editEmployeeIndex] = this.editEmployeeForm.value;
    if (this.editEmployeeForm.controls.dependents.value) {
      this.employerDetails.employees[this.editEmployeeIndex].dependents = this.editEmployeeForm.controls.dependents.value;
    }
    localStorage.setItem('employerDetails', JSON.stringify(this.employerDetails));
    this.editEmployeeIndex = null;
    this.rows = [...this.rows];
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
}
