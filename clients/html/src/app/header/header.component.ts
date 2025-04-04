import { Component } from '@angular/core';

@Component({
  selector: 'app-header',
  template: `
    <nav class="main-header navbar navbar-expand-lg">
      <div class="container">
        <a class="navbar-brand pt-3 pb-3 pe-3" href="#">
          <img src="assets/images/mhc_logo.svg" width="126px" height="40" alt="MHC Site logo" />
        </a>

        <div class="collapse navbar-collapse" id="navbarNavDropdown">
          <ul class="navbar-nav">
            <li class="nav-item active">
              <a class="nav-link main-link" href="#">Employer Quick Quote</a>
            </li>
          </ul>
        </div>
      </div>
    </nav>
  `,
  styleUrls: ['./header.component.scss'],
  standalone: true,
})
export class HeaderComponent {}
