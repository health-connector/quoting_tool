const startOnDates = { dates: ['2020/08/01', '2020/09/01'], is_late_rate: false };

describe('landing page', () => {
  beforeEach(() => {
    cy.server();
    cy.route('**/start_on_dates*', startOnDates).as('startDates');
    cy.visit('/');
  });

  it('Should allow user to enter in employee information', () => {
    cy.wait('@startDates');
    cy.get('h2.heading-text').contains('Employer Information');
    cy.get('#effectiveDate').select('August, 2020');
    cy.get('#sicInput input')
      .click()
      .type('0111');
    cy.get('#zip input')
      .click()
      .type('01001{enter}');

    cy.get('[data-cy="add-employee-btn"]').click();

    cy.get('[data-cy="first-name-input"]').type('Bob');
    cy.get('[data-cy="last-name-input"]').type('Johnson');
    cy.get('[data-cy="dob-input"]')
      .click()
      .type('01/01/1970');
    cy.get('[data-cy="coverage-type"]').select('Both');
    cy.get('[data-cy="save-roster"]').click();
    // cy.get('[data-cy="view-plans"]').click();
  });
});
