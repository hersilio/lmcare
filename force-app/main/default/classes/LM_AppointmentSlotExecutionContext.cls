public class LM_AppointmentSlotExecutionContext {
    
    // Lista de logs gerada DURANTE cada execute()
    private static List<PerformanceLog> executionLogs;

    // Inicializa a lista se estiver null
    private static void ensureInit() {
        if (executionLogs == null) {
            executionLogs = new List<PerformanceLog>();
        }
    }

    // Método chamado pelas classes internas
    public static void addLog(PerformanceLog log) {
        ensureInit();
        executionLogs.add(log);
    }

    // Batch vai buscar estes logs no final de cada execute()
    public static List<PerformanceLog> flushLogs() {
        ensureInit();
        // List<PerformanceLog> result = executionLogs.deepClone();
        // executionLogs.clear();
        return executionLogs;
    }
}