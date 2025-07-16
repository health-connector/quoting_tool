describe('Quoting Tool User Navigation', () => {
  it('Landing page loads correctly', () => {
    cy.visit('/');
  });

  it('Landing page headings are correct', () => {
    cy.visit('/');
    cy.get('.col-12 > .heading-text').should('have.text', 'Employer Information');
    cy.get('.col-md-12 > .heading-text').should('have.text', 'Employee Roster');
  });

  it('Sets the effective date, SIC, and ZIP code', () => {
    cy.visit('/');

    // Click on Effective Date dropdown and select the first option
    cy.get('#effectiveDate').select(1);

    // Set the effective date to the first option
    cy.get('#sicInput > .autocomplete-container > .input-container > .ng-untouched').type('0111');
    cy.tab();

    // Set the ZIP code to the 01022
    cy.get('.input-container > .ng-pristine').type('01022');
    cy.tab();

    // County should be set to Hampden
    cy.get('#countyField').should('have.value', 'Hampden');
  });

  it('Displays a modal and allows file attachment', () => {
    cy.visit('/');
    cy.get('.upload-employee-roster').click();
    cy.get('#file').click();
    cy.get('#file').attachFile('a-quoting-tool-test.xlsx');
    cy.get('#file-upload-btn').click();
    cy.get('[employee-index="29"] > .household').should('be.visible');
    cy.get('[ng-reflect-name="29"] > .ps-2 > :nth-child(2) > .dependent').should('be.visible');
  });

  it('Can upload an employee roster', () => {
    cy.visit('/');

    // Click on Effective Date dropdown and select the first option
    cy.get('#effectiveDate').select(1);

    // Set the effective date to the first option
    cy.get('#sicInput > .autocomplete-container > .input-container > .ng-untouched').type('0111');
    cy.tab();

    // Set the ZIP code to the 01022
    cy.get('.input-container > .ng-pristine').type('01022');
    cy.tab();

    cy.get('.upload-employee-roster').click();
    cy.get('#file').click();
    cy.get('#file').attachFile('a-quoting-tool-test.xlsx');
    cy.get('#file-upload-btn').click();

    cy.get('.btn-success').click();

    cy.get('.ngx-datatable').should('be.visible');
  });

  it('Displays the correct number of plans', () => {
    cy.visit('/');
    // Upload Employee Roster
    // Click on Effective Date dropdown and select the first option
    cy.get('#effectiveDate').select(1);

    // Set the effective date to the first option
    cy.get('#sicInput > .autocomplete-container > .input-container > .ng-untouched').type('0111');
    cy.tab();

    // Set the ZIP code to the 01022
    cy.get('.input-container > .ng-pristine').type('01022');
    cy.tab();

    cy.get('.upload-employee-roster').click();
    cy.get('#file').click();
    cy.get('#file').attachFile('a-quoting-tool-test.xlsx');
    cy.get('#file-upload-btn').click();

    cy.get('.btn-success').click();

    // Save the Roster
    cy.get('.btn-success').should('be.visible');
    cy.get('.btn-success').click();

    cy.wait(200);
    cy.get('.mb-4 > :nth-child(2)').click();
    cy.get(':nth-child(30) > :nth-child(1)').should('be.visible');
    cy.get('.fw-bold').should('contain.text', 'Displaying 30 Plans');
  });
});
