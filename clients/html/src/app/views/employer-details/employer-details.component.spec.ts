import { ComponentFixture, TestBed, waitForAsync } from '@angular/core/testing';
import { CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { EmployerDetailsComponent } from './employer-details.component';
import { NavComponent } from '../../components/nav/nav.component';
import { ReactiveFormsModule, FormBuilder, FormArray } from '@angular/forms';
import { RouterTestingModule } from '@angular/router/testing';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { AutocompleteLibModule } from 'angular-ng-autocomplete';
import { CoverageTypePipe } from '../../pipes/coverage-type.pipe';
import { provideHttpClient, withInterceptorsFromDi } from '@angular/common/http';
import { By } from '@angular/platform-browser';

describe('EmployerDetailsComponent', () => {
  let component: EmployerDetailsComponent;
  let fixture: ComponentFixture<EmployerDetailsComponent>;

  // create new instance of FormBuilder
  const formBuilder: FormBuilder = new FormBuilder();

  beforeEach(waitForAsync(() => {
    TestBed.configureTestingModule({
      schemas: [CUSTOM_ELEMENTS_SCHEMA],
      imports: [
        ReactiveFormsModule,
        NgbModule,
        RouterTestingModule,
        AutocompleteLibModule,
        BrowserAnimationsModule,
        EmployerDetailsComponent,
        NavComponent,
        CoverageTypePipe,
      ],
      providers: [
        { provide: FormBuilder, useValue: formBuilder },
        provideHttpClient(withInterceptorsFromDi()),
        provideHttpClientTesting(),
      ],
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

  it('should have Employee Roster section with correct elements', () => {
    // Ensure showEmployeeRoster is false so the buttons are present
    component.showEmployeeRoster = false;
    fixture.detectChanges();

    // Use debugElement and By for more robust querying
    const debugElement = fixture.debugElement;

    // Find the specific H2 element by its text content, making the test less brittle to structure changes
    const h2Elements = debugElement.queryAll(By.css('h2'));
    const titleElement = h2Elements.find((el) => el.nativeElement.textContent.trim() === 'Employee Roster');
    expect(titleElement).withContext('Expected to find an H2 element with text "Employee Roster"').toBeTruthy();

    // Find buttons using By.css for consistency
    const uploadEmployeeRosterBtn = debugElement.query(By.css('.upload-employee-roster'));
    const addNewEmployeeBtn = debugElement.query(By.css('.add-new-employee'));

    // Assert buttons exist and check their text content using textContent.trim() for robustness
    expect(uploadEmployeeRosterBtn).withContext('Expected to find the "Upload Employee Roster" button').toBeTruthy();
    expect(uploadEmployeeRosterBtn.nativeElement.textContent.trim()).toContain('Upload Employee Roster');

    expect(addNewEmployeeBtn).withContext('Expected to find the "Add Employee" button').toBeTruthy();
    expect(addNewEmployeeBtn.nativeElement.textContent.trim()).toContain('Add Employee');
  });

  it('should have valid quote form if required fields are filled in', () => {
    // Set controls with appropriate string values
    component.quoteForm.controls.effectiveDate.setValue('October 2019');
    component.quoteForm.controls.sic.setValue('0111'); // Use SIC code string
    component.quoteForm.controls.zip.setValue('01001'); // Use Zip code string
    component.quoteForm.controls.county.setValue('Hampden'); // Set county value

    // Adds employees to form for validation
    const control = <FormArray>component.quoteForm.controls.employees;
    control.push(
      formBuilder.group({
        firstName: ['John'],
        lastName: ['Doe'],
        dob: ['2000-10-02'],
        coverageKind: ['both'],
        dependents: formBuilder.array([]),
      }),
    );

    expect(component.quoteForm.valid).toBeTruthy();
  });

  it('add new employee button should add new employee to form', () => {
    // Ensure the button is present
    component.showEmployeeRoster = false;
    fixture.detectChanges();

    const button = fixture.nativeElement.querySelector('.add-new-employee');
    expect(component.quoteForm.controls.employees.value.length).toEqual(0);
    button.click();
    fixture.detectChanges();
    expect(component.quoteForm.controls.employees.value.length).toEqual(1);
    button.click();
    fixture.detectChanges();
    expect(component.quoteForm.controls.employees.value.length).toEqual(2);
  });
});
