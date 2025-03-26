import { Component, OnInit } from '@angular/core';
import carriers from '../../../data/qhp.json';
import { Router } from '@angular/router';
import { PlanFilterComponent } from '../../plan-filter/plan-filter.component';
import { NavComponent } from '../../nav/nav.component';

@Component({
  selector: 'app-employer-details-health',
  templateUrl: './employer-details-health.component.html',
  styleUrls: ['./employer-details-health.component.css'],
  standalone: true,
  imports: [NavComponent, PlanFilterComponent]
})
export class EmployerDetailsHealthComponent implements OnInit {
  public employerDetails: any;
  public effectiveDate: any;
  public erEmployees: any;
  public costShownText: any;
  public carriers = carriers;

  constructor(private router: Router) {}

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
