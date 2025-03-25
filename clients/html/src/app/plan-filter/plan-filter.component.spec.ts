import { ComponentFixture, TestBed, waitForAsync } from '@angular/core/testing';

import { PlanFilterComponent } from './plan-filter.component';
import { FormsModule } from '@angular/forms';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { RouterTestingModule } from '@angular/router/testing';
import { HttpClientTestingModule } from '@angular/common/http/testing';
import { PlanFilterPipe } from './plan-filter.pipe';
import { OrderByPipe } from './order-by.pipe';

const data = {
  effectiveDate: 'October 2019',
  sic: {
    industryGroupLabel: 'Cash Grains',
    standardIndustryCodeFull: '0112: Rice',
    standardIndustryCodeCode: '0112',
    standardIndustryCodeLabel: 'Rice'
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
          relationship: 'spouse'
        },
        {
          firstName: 'James',
          lastName: 'Smith',
          dob: '1954-12-19T05:00:00.000Z',
          relationship: 'child'
        }
      ]
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
          relationship: 'spouse'
        }
      ]
    },
    {
      firstName: 'Sean ',
      lastName: 'King',
      dob: '2001-02-01T05:00:00.000Z',
      coverageKind: 'both',
      dependents: []
    },
    {
      firstName: 'Lauren',
      lastName: 'Morris',
      dob: '1995-08-01T04:00:00.000Z',
      coverageKind: 'both',
      dependents: []
    }
  ]
};

describe('PlanFilterComponent', () => {
  let component: PlanFilterComponent;
  let fixture: ComponentFixture<PlanFilterComponent>;

  beforeEach(waitForAsync(() => {
    TestBed.configureTestingModule({
    imports: [NgbModule, BrowserAnimationsModule, RouterTestingModule, HttpClientTestingModule, FormsModule, PlanFilterComponent, PlanFilterPipe, OrderByPipe]
}).compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(PlanFilterComponent);
    component = fixture.componentInstance;
    localStorage.setItem('employerDetails', JSON.stringify(data));
  });

  it('should create', () => {
    component.planType = 'health';
    fixture.detectChanges();
    expect(component).toBeTruthy();
  });

  it('Choose type should have One Carrier, One Plan, and One Level if health', () => {
    component.planType = 'health';
    component.isLoading = false;
    fixture.detectChanges();
    const options = component.planOptions.filter((plan) => plan.view === component.planType);
    expect(options.length).toEqual(3);
  });

  xit('should have the table headers for health if plan type health', () => {
    component.planType = 'health';
    component.isLoading = false;
    fixture.detectChanges();
    const headers = fixture.nativeElement.querySelectorAll('th');
    expect(headers[0].innerText).toEqual('Plan name/Summary of Benefits');
    expect(headers[1].innerText).toEqual('Benefit Cost');
    expect(headers[2].innerText).toEqual('Annual Deductible Family/individual');
    expect(headers[3].innerText).toEqual('Maximum out of Pocket Family/individual');
    expect(headers[4].innerText).toEqual('Maximum Monthly Employer Cost');
  });

  xit('filter button should be disabled until a type is chosen', () => {
    component.planType = 'health';
    fixture.detectChanges();
    const button = fixture.nativeElement.querySelector('.filter-btn');
    expect(button.disabled).toEqual(true);
  });

  xit('filter button should be enabled if a type is chosen', () => {
    component.planType = 'health';
    fixture.detectChanges();
    const select = fixture.nativeElement.querySelector('select');
    const button = fixture.nativeElement.querySelector('.filter-btn');
    select.value = select.options[1].value;
    component.filterSelected = true;
    fixture.detectChanges();
    expect(button.disabled).toEqual(false);
  });

  it('Choose type should have One Plan if dental', () => {
    component.planType = 'dental';
    fixture.detectChanges();
    const options = component.planOptions.filter((plan) => plan.view === component.planType);
    expect(options.length).toEqual(1);
  });

  xit('should have the table headers for dental if plan type dental', () => {
    component.planType = 'dental';
    fixture.detectChanges();
    const headers = fixture.nativeElement.querySelectorAll('th');
    expect(headers[0].innerText).toEqual('Plan name');
    expect(headers[1].innerText).toEqual('Services');
    expect(headers[2].innerText).toEqual('Monthly Plan Premiums');
    expect(headers[3].innerText).toEqual('Annual Deductible');
    expect(headers[4].innerText).toEqual('Maximum Monthly Employer Cost');
  });
});
