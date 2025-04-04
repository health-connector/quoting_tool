import { Component, OnInit, inject } from '@angular/core';
import { Router } from '@angular/router';
// import carriers from '../../../data/carriers.json'; // Removed unused import
import { NavComponent } from '../../nav/nav.component';
import { PlanFilterComponent } from '../../plan-filter/plan-filter.component';
import { RosterEntry } from '../../data/sponsor_roster'; // Import RosterEntry

// Define interface for employer details structure
interface EmployerDetails {
  employees: RosterEntry[];
  // Add other properties if needed from the actual stored object
}

@Component({
  selector: 'app-employer-details-health',
  standalone: true,
  template: `
    <div class="container mt-3">
      <app-nav [validForm]="true" myPath="Health" />
      <div class="row">
        <div class="col-12 mt-2">
          <p class="main-text">
            Select a benefit model to view the plans available to you.
            <span
              class="plan-tooltip"
              placement="bottom"
              ngbTooltip="Employer chooses a single health plan and all employees will enroll in that same plan."
              >One Plan</span
            >
            allows you to offer one plan from one health plan to your employees.
            <span
              class="plan-tooltip"
              placement="bottom"
              ngbTooltip="Employer chooses an insurance company (carrier). Employees can choose any plan from that carrier at the Platinum, Gold, or Silver level."
              >One Carrier</span
            >
            allows you to offer a range of plans from a single health insurance company (carrier).
            <span
              class="plan-tooltip"
              placement="bottom"
              ngbTooltip="Employer chooses a Gold or Silver metal level. Employees can choose a plan from any insurance company (carrier) at the level."
              >One Level</span
            >
            allows you to offer plans of a specific benefit level (gold or silver) across all available health insurers.
            Learn more about our
            <a href="https://www.mahealthconnector.org/business/employers/employee-choice" target="_blank"
              >benefit models</a
            >.<br /><br />
            <i class="fas fa-sticky-note pe-2 fa-lg"></i>
            <strong
              >Note: The rates displayed for plans here represent 100% employer contribution to plan premium. You can
              choose to contribute less when you apply.
            </strong>
          </p>
          <strong
            ><i class="fas fa-stethoscope mr-2"></i
            ><a href="https://ma.checkbookhealth.org/mashop/index.cfm" target="_blank">Find My Doctor</a></strong
          >
        </div>
      </div>
      <app-plan-filter planType="health" />
    </div>
  `,
  styleUrls: ['./employer-details-health.component.css'],
  imports: [NavComponent, PlanFilterComponent],
})
export class EmployerDetailsHealthComponent implements OnInit {
  private router = inject(Router);
  public employerDetails: EmployerDetails | null = null;
  public erEmployees: RosterEntry[] = [];
  public costShownText: string = '';

  ngOnInit() {
    const erDetails = localStorage.getItem('employerDetails');
    this.employerDetails = erDetails ? (JSON.parse(erDetails) as EmployerDetails) : null;

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
