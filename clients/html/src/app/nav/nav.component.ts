import { Component, OnInit, input } from '@angular/core';
import { RouterLink } from '@angular/router';
import { NgFor, NgClass } from '@angular/common';

@Component({
  selector: 'app-nav',
  template: `
    <div class="row">
      <div class="col-12">
        <ul class="nav">
          <li class="nav-item" *ngFor="let link of navLinks">
            <a
              class="nav-link"
              [ngClass]="{
                disabled: isFormValid(link.name),
                active: isLinkActive(link.name)
              }"
              [routerLink]="link.path"
              >{{ link.name }}</a
            >
          </li>
        </ul>
      </div>
    </div>
  `,
  styleUrls: ['./nav.component.scss'],
  standalone: true,
  imports: [NgFor, NgClass, RouterLink]
})
export class NavComponent implements OnInit {
  validForm = input<string>();
  myPath = input<string>();

  navLinks = [
    { path: '/employer-details', name: 'Employer Details' },
    { path: '/employer-details/health', name: 'Health' },
    { path: '/employer-details/dental', name: 'Dental' }
  ];

  ngOnInit() {}

  isFormValid(name) {
    if (name === 'Health') {
      return !this.validForm();
    }

    if (name === 'Dental') {
      return !this.validForm();
    }
  }

  isLinkActive(link) {
    if (link === this.myPath()) {
      return true;
    } else {
      return false;
    }
  }
}
