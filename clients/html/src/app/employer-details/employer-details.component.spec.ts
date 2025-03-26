import { ComponentFixture, TestBed, waitForAsync } from '@angular/core/testing';
import { CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { EmployerDetailsComponent } from './employer-details.component';
import { NavComponent } from '../nav/nav.component';
import { ReactiveFormsModule, FormBuilder, FormArray } from '@angular/forms';
import { RouterTestingModule } from '@angular/router/testing';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { AutocompleteLibModule } from 'angular-ng-autocomplete';
import { CoverageTypePipe } from './coverage-type.pipe';
import { provideHttpClient, withInterceptorsFromDi } from '@angular/common/http';

describe('EmployerDetailsComponent', () => {
  let component: EmployerDetailsComponent;
  let fixture: ComponentFixture<EmployerDetailsComponent>;

  // create new instance of FormBuilder
  const formBuilder: FormBuilder = new FormBuilder();

  beforeEach(waitForAsync(() => {
    TestBed.configureTestingModule({
    schemas: [CUSTOM_ELEMENTS_SCHEMA],
    imports: [ReactiveFormsModule,
        NgbModule,
        RouterTestingModule,
        AutocompleteLibModule,
        BrowserAnimationsModule,
        EmployerDetailsComponent, NavComponent, CoverageTypePipe],
    providers: [{ provide: FormBuilder, useValue: formBuilder }, provideHttpClient(withInterceptorsFromDi()), provideHttpClientTesting()]
}).compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(EmployerDetailsComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should display the quote form', () => {
    expect(component.quoteForm.controls['effectiveDate']).toBeTruthy();
    expect(component.quoteForm.controls['sic']).toBeTruthy();
    expect(component.quoteForm.controls['zip']).toBeTruthy();
    expect(component.quoteForm.controls['county']).toBeTruthy();
  });

  it('quote form should be invalid', () => {
    expect(component.quoteForm.valid).toBeFalsy();
  });

  it('should have Employer Information section', () => {
    const title = fixture.nativeElement.querySelectorAll('h2')[0];
    expect(title.innerText).toEqual('Employer Information');
  });

  xit('should have Employee Roster section', () => {
    const title = fixture.nativeElement.querySelectorAll('h2')[1];
    const uploadEmployeeRosterBtn = fixture.nativeElement.querySelector('.upload-employee-roster');
    const addNewEmployeeBtn = fixture.nativeElement.querySelector('.add-new-employee');
    expect(title.innerText).toEqual('Employee Roster');
    expect(uploadEmployeeRosterBtn.innerText).toEqual('Upload Employee Roster');
    expect(addNewEmployeeBtn.innerText).toEqual('Add Employee');
  });

  it('should have valid quote form if required fields are filled in', () => {
    component.quoteForm = formBuilder.group({
      effectiveDate: 'October 2019',
      sic: {
        industryGroupLabel: 'Cash Grains',
        standardIndustryCode: '0111',
        standardIndustryCodeFull: '0111: Wheat',
        standardIndustryCodeLabel: 'Wheat'
      },
      zip: { zipCode: '01001', county: 'Hampden' },
      employees: formBuilder.array([])
    });
    // Adds employees to form
    const control = <FormArray>component.quoteForm.controls.employees;
    control.push(
      formBuilder.group({
        firstName: ['John'],
        lastName: ['Doe'],
        dob: ['2000-10-02'],
        coverageKind: ['both'],
        dependents: formBuilder.array([])
      })
    );

    expect(component.quoteForm.valid).toBeTruthy();
  });

  xit('add new employee button should add new employee to form', () => {
    const button = fixture.nativeElement.querySelector('.add-new-employee');
    expect(component.quoteForm.controls.employees.value.length).toEqual(0);
    button.click();
    expect(component.quoteForm.controls.employees.value.length).toEqual(1);
    button.click();
    expect(component.quoteForm.controls.employees.value.length).toEqual(2);
  });
});
