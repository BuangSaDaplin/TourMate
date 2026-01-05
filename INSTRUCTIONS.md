# How to Access Different Dashboards

The Tour Mate app displays different dashboards based on the user's role, which is stored in the Firestore database. To access the Admin, Tour Guide, or Tourist dashboards, you need to manually change the `role` field of a user in the Firebase Firestore console.

## Prerequisites

1.  A Firebase project linked to this application.
2.  At least one user registered in the application.

## Steps to Change User Role

1.  **Open your Firebase project console.**
2.  Navigate to the **Firestore Database** section.
3.  In the `users` collection, find the document corresponding to the user you want to modify. The document ID is the same as the user's UID from Firebase Authentication.
4.  Click on the user's document to view its fields.
5.  Find the `role` field and click the edit icon.
6.  Change the value of the `role` field to one of the following:
    *   `Admin`
    *   `Tour Guide`
    *   `Tourist`
7.  Click **Update** to save the changes.
8.  Relaunch the application. The app will now display the dashboard corresponding to the new role.

## Default Role

By default, all new users are assigned the `Tourist` role upon registration.
