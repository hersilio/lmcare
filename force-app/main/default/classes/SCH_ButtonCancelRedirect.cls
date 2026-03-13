public class SCH_ButtonCancelRedirect {
    public Boolean showModal { get; set; }

    public SCH_ButtonCancelRedirect(ApexPages.StandardController controller) {
        showModal = false;
    }

    public void openModal() {
        showModal = true;
    }

    public void closeModal() {
        showModal = false;
    }
}