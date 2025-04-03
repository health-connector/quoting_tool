import { ComponentFixture, TestBed, waitForAsync } from '@angular/core/testing';

import { EmployerDetailsDentalComponent } from './employer-details-dental.component';
import { PlanFilterComponent } from '../../plan-filter/plan-filter.component';
import { RouterTestingModule } from '@angular/router/testing';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { provideHttpClient, withInterceptorsFromDi } from '@angular/common/http';

describe('EmployerDetailsDentalComponent', () => {
  let component: EmployerDetailsDentalComponent;
  let fixture: ComponentFixture<EmployerDetailsDentalComponent>;

  beforeEach(waitForAsync(() => {
    TestBed.configureTestingModule({
      imports: [RouterTestingModule, EmployerDetailsDentalComponent, PlanFilterComponent],
      providers: [provideHttpClient(withInterceptorsFromDi()), provideHttpClientTesting()],
    }).compileComponents();
  }));

  beforeEach(() => {
    // Mock localStorage
    const mockEmployerDetails = {
      employees: [
        { dob: '1990-01-01', coverageKind: 'health', dependents: [] },
        { dob: '1985-05-15', coverageKind: 'dental', dependents: [] },
      ],
      sic: { standardIndustryCodeCode: '1234' },
      county: 'SomeCounty',
      zip: '12345',
      effectiveDate: '2024-01-01',
      // Add other necessary properties if PlanFilterComponent requires them
    };
    spyOn(localStorage, 'getItem').and.callFake((key: string) => {
      if (key === 'employerDetails') {
        return JSON.stringify(mockEmployerDetails);
      }
      return null;
    });

    fixture = TestBed.createComponent(EmployerDetailsDentalComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should have the default paragraph text', () => {
    const text = fixture.nativeElement.querySelector('.main-text').innerText;
    expect(text).toContain('Choose any dental plan from a single dental insurance carrier to offer for all employees');
  });
});
