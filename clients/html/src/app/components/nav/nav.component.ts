import { Component, input } from '@angular/core';
import { RouterLink } from '@angular/router';
import { NgClass } from '@angular/common';

@Component({
  selector: 'app-nav',
  template: `
    <div class="row">
      <div class="col-12">
        <ul class="nav">
          @for (link of navLinks; track link) {
            <li class="nav-item">
              <a
                class="nav-link"
                [ngClass]="{
                  disabled: isFormValid(link.name),
                  active: isLinkActive(link.name),
                }"
                [routerLink]="link.path"
                >{{ link.name }}</a
              >
            </li>
          }
        </ul>
      </div>
    </div>
  `,
  styleUrls: ['./nav.component.scss'],
  imports: [NgClass, RouterLink],
})
export class NavComponent {
  validForm = input<boolean>();
  myPath = input<string>();

  navLinks = [
    { path: '/employer-details', name: 'Employer Details' },
    { path: '/employer-details/health', name: 'Health' },
    { path: '/employer-details/dental', name: 'Dental' },
  ];

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
