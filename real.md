Sure! Here's a comprehensive and detailed prompt tailored to creating a mobile application where the **Finance** module is designed for managing fees, tracking student fee statuses, and ensuring that the system provides appropriate access to users (e.g., **staff per class**, **parents per child**, and **administrators monitoring fees**). We'll break down each feature and role in the system.

### **Objective**:

Create a **mobile app** that monitors **students' fee statuses**, enables **staff (per class)** to manage their specific student’s data, and gives **parents (per child)** access to their child’s fee information and academic progress. The **Finance module** will be integral for managing and tracking **fee payments** and **pending fees**.

The **Finance user** will be responsible for overseeing the fee status of all students. This includes the ability to mark fees as paid, monitor overdue payments, and notify parents/students about fee-related updates.

---

### **Core Features**:

---

### **1. User Roles and Access Control**:

#### **Finance User**:

* **Role Overview**: A **Finance User** will have full access to monitor and manage the fee statuses of **all students** across different classes and schools.

  * **Fee Monitoring**: Finance users can view all students' fee statuses (paid, pending, overdue).
  * **Pending Fees**: Track unpaid fees, generate reports on overdue payments, and manage alerts for both students and parents.
  * **Payment Management**: Can mark payments as complete or overdue.
  * **Fee Summary**: Display a summary of total collected fees vs. outstanding amounts for the entire school.
  * **Notifications**: Can send fee-related notifications to parents, students, or the admin.
  * **Reports**: Generate reports showing student fee history, pending payments, and collected amounts.

#### **Staff (per Class)**:

* **Role Overview**: Staff users (such as teachers) can access and manage fee-related information for **their own students** only.

  * **Access to Class-Specific Fee Data**: Teachers can view and monitor the fee status of students within their assigned class.
  * **Fee Reminders**: Teachers can send fee reminders or notifications to the students/parents about unpaid fees.
  * **Fee Status**: Teachers can view whether students have paid their fees, and view any outstanding payments.

#### **Parent (per Child)**:

* **Role Overview**: **Parents** have restricted access, allowing them to see **only their child’s fee information** and progress.

  * **Fee Overview**: Parents can view the total fees for their child, payments made, and any pending or overdue fees.
  * **Notifications**: Get notified when fees are due, overdue, or if new payments are recorded.
  * **Payment History**: Display previous payment records for their child, including dates and amounts paid.

#### **Admin**:

* **Role Overview**: Admins have **full access** to all student and staff fee data.

  * **User Management**: Admins can create and assign roles (Finance User, Staff, Parent) to different users.
  * **Fee Reports**: View fee summaries for the entire school, track payments, overdue fees, and generate financial reports.
  * **System Settings**: Configure fee structures, payment deadlines, and update fee categories (tuition, extracurriculars, etc.).

---

### **2. Fee Management System**:

#### **Fee Dashboard**:

* **Real-Time Fee Tracking**: Display real-time data on fees, including **paid**, **pending**, and **overdue** status for each student.
* **Fee Categories**: Students may have multiple types of fees (e.g., **tuition**, **extracurricular**, **special courses**). Each category should be clearly displayed and managed.
* **Fee Payments**:

  * **Pending Fee Alerts**: Notification to parents and teachers if any fees are pending or overdue.
  * **Payment Confirmation**: Once a payment is made, update the student’s fee status to **paid** and generate receipts.
  * **Partial Payments**: Support for partial payments where the total fee can be broken down into smaller payments over time.

#### **Fee Summary**:

* **For Finance Users**: Provide a comprehensive view of the school’s total fee income, showing the status of fees (paid vs. overdue).
* **For Parents**: A summary of their child's fee status, including **total due**, **amount paid**, and **amount pending**.
* **For Admins**: Overview of all students' fee statuses and the ability to generate detailed reports on fee payment trends.

#### **Fee Payment Integration**:

* **Payment Gateway**: Integrate with a secure payment system (e.g., **Stripe**, **PayPal**, or local gateways) to allow **real-time fee payments** directly through the mobile app.
* **Payment History**: Each payment made by a parent should be logged with date, amount, and payment method.
* **Invoice Generation**: After each payment, automatically generate and send a payment receipt/invoice to the parent’s email or in-app notification.

---

### **3. Notification System**:

* **Fee Reminders**:

  * Notify parents about **upcoming fee deadlines** (e.g., **5 days before due date**).
  * Send **late fee reminders** if fees are not paid on time, with an option to make payments directly from the notification.
  * Send **success payment** notifications once fees have been successfully processed.
* **Push Notifications**:

  * Use **push notifications** to remind parents about **pending** or **overdue** fees.
  * Teachers can send messages to parents regarding any specific concerns related to fees.
* **SMS and Email Alerts**:

  * Send SMS or email reminders for **fee due dates**, **pending payments**, and **payment confirmations**.

---

### **4. User Profiles**:

#### **Parent Profile**:

* **Basic Info**: Display parent name, contact details, child’s name, and associated student information.
* **Fee Status**: Overview of fee payments (paid, pending, overdue) for their specific child.
* **Fee History**: View all past payments made for the child, along with dates and amounts.
* **Payment Options**: Easy access to make payments for pending fees directly through the app.

#### **Student Profile**:

* **Fee Breakdown**: Show a detailed breakdown of their **tuition**, **extracurricular**, and any other fees.
* **Payment Status**: Indicate whether their fees are paid, pending, or overdue.
* **Pending Notifications**: Alert the student if their fees are overdue.

#### **Finance User Profile**:

* **Fee Monitoring Dashboard**: Show all students and their respective fee statuses.
* **Fee Categories**: Track different types of fees and payments across different classes, grades, and students.
* **Generate Reports**: Ability to generate detailed reports of fee payments, overdue fees, and financial history.

#### **Staff Profile (per Class)**:

* **Class Overview**: Staff can view a list of students they are teaching along with their fee statuses.
* **Communication Tools**: Send messages to parents if there are concerns related to the fee status of students in their class.
* **Notification System**: Alert teachers when a student has an overdue fee.

---

### **5. Admin Features**:

* **User Management**:

  * **Create Users**: Admins can create new **finance users**, **teachers**, **parents**, and **students**.
  * **Role Assignment**: Assign specific roles such as **Finance User**, **Parent**, and **Teacher** based on user profile.

* **Fee Management**:

  * **Configure Fee Structure**: Admins can set up and modify the **fee structure** for each class, student, or academic year (tuition fees, special courses, extracurricular).
  * **Monitor Payments**: Track overall fee collections, overdue payments, and generate school-wide financial reports.
  * **Payment Confirmation**: Verify payments, and mark them as complete in the system.

* **Report Generation**:

  * Generate financial reports showing the status of student fees, payments, outstanding amounts, and collections.
  * View **year-over-year** reports of collected fees.

---

### **6. Technology Stack**:

* **Frontend (Mobile)**: Flutter (Cross-platform mobile app for iOS and Android)

  * **Firebase**: Authentication for managing user logins securely.
  * **Provider or Riverpod**: State management for maintaining app-wide state (user data, fee status, notifications).
  * **Push Notifications**: Firebase Cloud Messaging (FCM) for real-time notifications.

* **Backend (Node.js)**:

  * **Express.js**: For handling API requests (fee tracking, user management, notifications).
  * **MongoDB**: Store user data, fee data, payment history, and transaction logs.
  * **JWT Authentication**: To securely handle role-based access control (parents can only see their child’s fee status, teachers can only see students in their class).
  * **Stripe/PayPal API**: For processing fee payments and handling payment-related operations.

* **Database**:

  * **MongoDB**: A NoSQL database for storing flexible student data, fee data, payment logs, and user profiles.
  * **Data Encryption**: Ensure that all sensitive data like payment details is encrypted for security.

---

### **7. Security**:

* **Role-Based Access Control (RBAC)**: Ensure users (e.g., parents, teachers, finance users) can only access data they are authorized to view.
* **Data Encryption**: Secure all payment transactions and personal data.
* **Secure Payment Gateway**: Use secure third-party payment gateways like **Stripe** or **PayPal** for payment transactions.

---

### \*\*Detailed Use


Case Example\*\*:

1. **Parent**:

   * Logs in and sees the **Fee Overview** for their child.
   * **Pending Fees** appear clearly with a **due date**.
   * Receives a notification 5 days before the fee is due.
   * Can make the payment directly through the app.
   * After payment, receives an **invoice** and **payment confirmation**.

2. **Finance User**:

   * Can view and monitor **all students’ fee statuses** (paid, pending, overdue).
   * Sends reminders for overdue fees.
   * Generates monthly or quarterly reports on **collected fees** and **pending payments**.

3. **Staff**:

   * View their class list and see which students have pending or paid fees.
   * Communicates with **parents** regarding fee payment reminders or concerns.

---

This mobile app will allow seamless tracking of student fees, real-time updates, and notifications for all stakeholders.
