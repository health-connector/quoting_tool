import { Component, OnInit, inject } from '@angular/core';
import carriers from '../../../data/qdp.json';
import { Router } from '@angular/router';
import { PlanFilterComponent } from '../../plan-filter/plan-filter.component';
import { NavComponent } from '../../nav/nav.component';

@Component({
    selector: 'app-employer-details-dental',
    template: `
<div class="container mt-3">
  <app-nav [validForm]="true" myPath="Dental" />
  <div class="row">
    <div class="col-12 mt-2">
      <p class="main-text">
        Choose any dental plan from a single dental insurance carrier to offer for all employees. All available plans are displayed below.<br /><br />
        The monthly cost displayed here is based on 100% employer contribution to plan premiums. However, you can choose to contribute less when you apply.
      </p>
      <strong
        ><i class="fas fa-stethoscope mr-2"></i
        ><a href="https://ma.checkbookhealth.org/mashop/index.cfm" target="_blank">Find My Doctor</a></strong
      >
    </div>
  </div>
  <app-plan-filter [carrierPlans]="carriers" planType="dental" />
</div>

`,
    styleUrls: ['./employer-details-dental.component.css'],
    imports: [NavComponent, PlanFilterComponent]
})
export class EmployerDetailsDentalComponent implements OnInit {
  private router = inject(Router);
  public employerDetails: any;
  public effectiveDate: any;
  public erEmployees: any;
  public costShownText: any;
  public carriers = carriers;

  ngOnInit() {
    const erDetails = localStorage.getItem('employerDetails');
    this.employerDetails = JSON.parse(erDetails);

    if (this.employerDetails) {
      this.erEmployees = this.employerDetails.employees;
      if (this.erEmployees.length > 1) {
        this.costShownText = `${this.erEmployees.length} people`;
      } else {
        this.costShownText = `${this.erEmployees.length} person`;
      }
    } else {
      this.router.navigate(['/']);
    }
  }
}
