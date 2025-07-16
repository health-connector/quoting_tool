import { ComponentFixture, TestBed, waitForAsync } from '@angular/core/testing';

import { PlanFilterComponent } from './plan-filter.component';
import { FormsModule } from '@angular/forms';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { PlanFilterPipe } from '../../pipes/plan-filter.pipe';
import { OrderByPipe } from '../../pipes/order-by.pipe';
import { provideHttpClient, withInterceptorsFromDi } from '@angular/common/http';
import { provideRouter } from '@angular/router';

const data = {
  effectiveDate: 'October 2019',
  sic: {
    industryGroupLabel: 'Cash Grains',
    standardIndustryCodeFull: '0112: Rice',
    standardIndustryCodeCode: '0112',
    standardIndustryCodeLabel: 'Rice',
  },
  zip: { zipCode: '01001', county: 'Hampden' },
  county: 'Hampden',
  employees: [
    {
      firstName: 'Larry',
      lastName: 'Smith',
      dob: '1924-01-12T05:00:00.000Z',
      coverageKind: 'both',
      dependents: [
        {
          firstName: 'Sue',
          lastName: 'Smith',
          dob: '2004-11-01T05:00:00.000Z',
          relationship: 'spouse',
        },
        {
          firstName: 'James',
          lastName: 'Smith',
          dob: '1954-12-19T05:00:00.000Z',
          relationship: 'child',
        },
      ],
    },
    {
      firstName: 'Jane',
      lastName: 'Brown',
      dob: '1990-11-01T05:00:00.000Z',
      coverageKind: 'both',
      dependents: [
        {
          firstName: 'John',
          lastName: 'Brown',
          dob: '2000-11-01T05:00:00.000Z',
          relationship: 'spouse',
        },
      ],
    },
    {
      firstName: 'Sean ',
      lastName: 'King',
      dob: '2001-02-01T05:00:00.000Z',
      coverageKind: 'both',
      dependents: [],
    },
    {
      firstName: 'Lauren',
      lastName: 'Morris',
      dob: '1995-08-01T04:00:00.000Z',
      coverageKind: 'both',
      dependents: [],
    },
  ],
};

describe('PlanFilterComponent', () => {
  let component: PlanFilterComponent;
  let fixture: ComponentFixture<PlanFilterComponent>;

  beforeEach(waitForAsync(() => {
    TestBed.configureTestingModule({
      imports: [NgbModule, BrowserAnimationsModule, FormsModule, PlanFilterComponent, PlanFilterPipe, OrderByPipe],
      providers: [provideHttpClient(withInterceptorsFromDi()), provideHttpClientTesting(), provideRouter([])],
    }).compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(PlanFilterComponent);
    component = fixture.componentInstance;
    localStorage.setItem('employerDetails', JSON.stringify(data));
    fixture.componentRef.setInput('planType', 'health');
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('Choose type should have One Carrier, One Plan, and One Level if health', () => {
    component.isLoading = false;
    const options = component.planOptions.filter((plan) => plan.view === component.planType());
    expect(options.length).toEqual(3);
  });

  it('should have the table headers for health if plan type health', () => {
    component.isLoading = false;
    component.changePackageFilter('single_product');
    fixture.detectChanges();
    const headers = fixture.nativeElement.querySelectorAll('th');
    const headerTexts = Array.from(headers).map((h: HTMLElement) => h.innerText.trim());

    expect(headerTexts[0]).toContain('Plan name');
    expect(headerTexts[1]).toContain('Benefit Cost');
    expect(headerTexts[2].toLowerCase()).toContain('deductible');
    expect(headerTexts[2].toLowerCase()).toContain('individual');
    expect(headerTexts[2].toLowerCase()).toContain('family');
    expect(headerTexts[3].toLowerCase()).toContain('out of pocket');
    expect(headerTexts[3].toLowerCase()).toContain('individual');
    expect(headerTexts[3].toLowerCase()).toContain('family');
    expect(headerTexts[4].toLowerCase()).toMatch(/monthly cost|maximum monthly employer cost/);
  });

  it('filter button should be disabled until a type is chosen', () => {
    component.isLoading = false;
    fixture.detectChanges();
    const button = fixture.nativeElement.querySelector('.filter-btn');
    expect(button.disabled).toEqual(true);
  });

  it('filter button should be enabled if a type is chosen', () => {
    component.isLoading = false;
    fixture.detectChanges();
    // Find the first visible radio button (plan selection)
    const radios = fixture.nativeElement.querySelectorAll('input[type="radio"]');
    const visibleRadio = Array.from(radios).find((radio: HTMLInputElement) => !radio.closest('label')?.hidden);
    expect(visibleRadio).withContext('Radio button for plan selection not found in DOM').not.toBeNull();
    if (!visibleRadio) return;
    (visibleRadio as HTMLInputElement).click();
    component.filterSelected = true;
    fixture.detectChanges();
    const button = fixture.nativeElement.querySelector('.filter-btn');
    expect(button.disabled).toEqual(false);
  });

  it('Choose type should have One Plan if dental', () => {
    fixture.componentRef.setInput('planType', 'dental');
    fixture.detectChanges();
    const options = component.planOptions.filter((plan) => plan.view === component.planType());
    expect(options.length).toEqual(1);
  });

  it('should have the table headers for dental if plan type dental', () => {
    component.isLoading = false;
    fixture.componentRef.setInput('planType', 'dental');
    component.changePackageFilter('single_product');
    fixture.detectChanges();
    const headers = fixture.nativeElement.querySelectorAll('th');
    const headerTexts = Array.from(headers).map((h: HTMLElement) => h.innerText.trim());

    expect(headerTexts[0].toLowerCase()).toContain('plan name');
    expect(headerTexts[1].toLowerCase()).toContain('services');
    expect(headerTexts[2].toLowerCase()).toContain('annual deductible');
    expect(headerTexts[3].toLowerCase()).toContain('out of pocket');
    expect(headerTexts[4].toLowerCase()).toContain('employer cost');
  });
});
